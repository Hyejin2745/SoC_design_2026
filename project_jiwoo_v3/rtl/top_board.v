`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// top_board : Karnaugh-map gate quiz + MUX quiz, top level (Nexys4 DDR)
//
//   Level 1 (Q1-Q3) : the K-map of a hidden gate is shown, the player finds the gate
//       BTNU = AND   BTNL = OR   BTNR = XOR      (choose the gate, the symbol is drawn on screen)
//       x[0] (SW0) up = NOT                      (inverts the gate: OR + NOT = NOR)
//       BTNC = submit / next screen
//   Level 2 (Q4-Q5) : MUX puzzles, the player sets A, B, C so the output equals the target number
//       Q4 : one 8:1 MUX (input number = {A,B,C}, A is the high bit)
//       Q5 : two 4:1 MUX (same select A,B) + one 2:1 MUX (select C)
//       x[3] (SW3) = A, x[2] (SW2) = B, x[1] (SW1) = C   (the output follows the switches at once)
//       sw4 (SW4) raised = submit / next screen          (BTNC works as well)
//
//   rst     : CPU_RESETN pin (active low: pressed = 0)
//   led_x   : [2:0] lives, [3] ready to submit
//   led_y   : unused (always off)
//   seg     : {CA..CG}      digit : AN[7:0]
//   7-seg   : [7]level [6]question no. [3]lives [2:0]score
//------------------------------------------------------------------------------
module top_board #(
    parameter DB_LOCK = 1_000_000   // button bounce lock: 1,000,000 clocks = 10ms (small in simulation)
) (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] x,
    input  wire       sw4,
    input  wire       BTNC,
    input  wire       BTNU,
    input  wire       BTNL,
    input  wire       BTNR,
    output wire [3:0] led_x,
    output wire [3:0] led_y,
    output wire [6:0] seg,
    output wire [7:0] digit,
    output wire [3:0] VGA_R,
    output wire [3:0] VGA_G,
    output wire [3:0] VGA_B,
    output wire       VGA_HS,
    output wire       VGA_VS
);
    //--------------------------------------------------------------------------
    // switches (read directly) and buttons (Button = synchronizer + single pulser)
    //   rst is active low and goes straight to every module.
    //   (the 25MHz pixel enable en25 comes from vga_sync)
    //--------------------------------------------------------------------------
    wire       sw_not = x[0];
    wire [1:0] sel    = {x[3], x[2]};   // A, B (select of both 4:1 MUX)
    wire       csel   = x[1];           // C (select of the 2:1 MUX)

    wire bc, bu, bl, br, s4;

    Button #(DB_LOCK) BT_C (clk, rst, BTNC, bc);
    Button #(DB_LOCK) BT_U (clk, rst, BTNU, bu);
    Button #(DB_LOCK) BT_L (clk, rst, BTNL, bl);
    Button #(DB_LOCK) BT_R (clk, rst, BTNR, br);
    Button #(DB_LOCK) BT_S (clk, rst, sw4,  s4);

    //--------------------------------------------------------------------------
    // control FSM
    //   'go' = submit / next screen. BTNC always works; SW4 works in level 2.
    //--------------------------------------------------------------------------
    wire [3:0] state;
    wire       game_clr, clr_round, ans_edit;
    wire       score_add, life_dec, upd_best, q_adv;
    wire       ans_ok, match, last_q, lives_zero;
    wire [1:0] level, lives;
    wire       go = bc | ((level == 2'd2) & s4);

    control_fsm u_fsm (
        clk, rst, go, ans_ok, match, last_q, lives_zero,
        state, game_clr, clr_round, ans_edit,
        score_add, life_dec, upd_best, q_adv
    );

    //--------------------------------------------------------------------------
    // score, lives, question number
    //--------------------------------------------------------------------------
    wire [2:0] qnum;
    wire [9:0] score, best;
    wire [7:0] pts;

    score_unit u_score (
        clk, rst, game_clr, score_add, life_dec, q_adv, upd_best,
        qnum, level, lives, score, best, pts, lives_zero, last_q
    );

    //--------------------------------------------------------------------------
    // fixed question
    //--------------------------------------------------------------------------
    wire [2:0] h_g1;
    wire [3:0] d0, d1, d2, d3, e0, e1, e2, e3, tgt;
    puzzle_rom u_puz (qnum, h_g1, d0, d1, d2, d3, e0, e1, e2, e3, tgt);

    //--------------------------------------------------------------------------
    // level 1 : player's gate and the K-map of the hidden gate
    //--------------------------------------------------------------------------
    wire [2:0] a_g1;
    wire       gate_set;
    answer_reg u_ans (clk, rst, clr_round, ans_edit, bu, bl, br, sw_not, a_g1, gate_set);

    wire [3:0] hid_val;
    kmap_val u_hid   (h_g1, hid_val);

    //--------------------------------------------------------------------------
    // level 2 : two 4:1 MUX (same select A,B) -> 2:1 MUX (select C)
    //--------------------------------------------------------------------------
    wire [3:0] mux_up  = (sel == 2'd0) ? d0 :
                         (sel == 2'd1) ? d1 :
                         (sel == 2'd2) ? d2 : d3;
    wire [3:0] mux_low = (sel == 2'd0) ? e0 :
                         (sel == 2'd1) ? e1 :
                         (sel == 2'd2) ? e2 : e3;
    wire [2:0] idx8    = {sel, csel};
    wire [3:0] mux_8   = (idx8 == 3'd0) ? d0 : (idx8 == 3'd1) ? d1 :
                         (idx8 == 3'd2) ? d2 : (idx8 == 3'd3) ? d3 :
                         (idx8 == 3'd4) ? e0 : (idx8 == 3'd5) ? e1 :
                         (idx8 == 3'd6) ? e2 : e3;
    wire       mode8   = (qnum == 3'd3);             // Q4 : single 8:1 MUX
    wire [3:0] mux_out = mode8 ? mux_8 : (csel ? mux_low : mux_up);

    // submit is allowed when a gate has been chosen (level 1) or always (level 2)
    assign ans_ok = (level == 2'd1) ? gate_set : 1'b1;
    assign match  = (level == 2'd1) ? (h_g1 == a_g1) : (mux_out == tgt);

    //--------------------------------------------------------------------------
    // score -> decimal
    //--------------------------------------------------------------------------
    wire [11:0] bcd_score, bcd_best, bcd_pts;
    bin2bcd u_bcd_score (score,          bcd_score);
    bin2bcd u_bcd_best  (best,           bcd_best);
    bin2bcd u_bcd_pts   ({2'b00, pts},   bcd_pts);

    //--------------------------------------------------------------------------
    // 7-segment : [7] level [6] question no. [3] lives [2:0] score (AN5, AN4 off)
    //--------------------------------------------------------------------------
    wire [31:0] seg_digits = { {2'b00, level},              // AN7
                               {1'b0, qnum} + 4'd1,         // AN6
                               8'hFF,                       // AN5, AN4 (off)
                               {2'b00, lives},              // AN3
                               bcd_score };                 // AN2..AN0
    Display8 DP0 (clk, rst, seg_digits, seg, digit);

    //--------------------------------------------------------------------------
    // VGA
    //--------------------------------------------------------------------------
    wire [9:0] vx, vy;
    wire       en25, v_hs, v_vs, v_active;
    vga_sync u_vga (clk, rst, en25, vx, vy, v_hs, v_vs, v_active);

    renderer u_render (
        clk, rst, en25, vx, vy, v_hs, v_vs, v_active,
        state, level, qnum, lives, lives_zero,
        bcd_score[11:8], bcd_score[7:4], bcd_score[3:0],
        bcd_best[11:8],  bcd_best[7:4],  bcd_best[3:0],
        bcd_pts[11:8],   bcd_pts[7:4],   bcd_pts[3:0],
        a_g1, h_g1,
        (state == 4'd3),            // reveal the hidden gate after a correct answer
        hid_val,
        d0, d1, d2, d3, e0, e1, e2, e3, tgt, sel, csel, mode8, mux_out,
        VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS
    );

    //--------------------------------------------------------------------------
    // LEDs
    //--------------------------------------------------------------------------
    assign led_x = {(state == 4'd2) & ans_ok,                 // ready to submit
                    lives[1] & lives[0], lives[1], |lives};   // lives bar (3 lives = 111)
    assign led_y = 4'b0000;                                   // RGB LED not used
endmodule
