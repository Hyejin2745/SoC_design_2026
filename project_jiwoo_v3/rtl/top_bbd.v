`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// top_bbd : Karnaugh-map gate quiz + 4:1 MUX quiz top level (Nexys4 DDR)
//
//   Level 1 (Q1-Q3) : the K-map of a hidden gate is shown, the player finds the gate
//       BTNU = AND   BTNL = OR   BTNR = XOR      (choose the gate, the symbol is drawn on screen)
//       SW0 up = NOT                             (inverts the gate: OR + NOT = NOR)
//       BTNC = submit / next screen
//   Level 2 (Q4-Q5) : MUX puzzles, the player sets A, B, C so the output equals the target number
//       Q4 : one 8:1 MUX (input number = {A,B,C}, A is the high bit)
//       Q5 : two 4:1 MUX (same select A,B) + one 2:1 MUX (select C)
//       SW3 = A (S1), SW2 = B (S0), SW1 = C      (the output follows the switches at once)
//       SW4 raised = submit / next screen        (BTNC works as well)
//
//   SW[4:0] = SW4..SW0
//   7-seg : [7]level [6]question no. [3]lives [2:0]score
//   LEDs  : LED[2:0] lives, LED[3] ready to submit; RGB LED shows the state
//------------------------------------------------------------------------------
module top_bbd #(
    parameter DIV_1M    = 100,    // 100MHz / 100 = 1MHz
    parameter DIV_1K    = 1000,   // 1MHz / 1000 = 1kHz
    parameter DB_STABLE = 10,     // debounce: 10 consecutive 1kHz samples = 10ms
    parameter NOTE_MS   = 150
) (
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,
    input  wire [4:0]  SW,
    input  wire        BTNC,
    input  wire        BTNU,
    input  wire        BTNL,
    input  wire        BTNR,
    output wire [15:0] LED,
    output wire        LED16_R,
    output wire        LED16_G,
    output wire        LED16_B,
    output wire        CA, CB, CC, CD, CE, CF, CG, DP,
    output wire [7:0]  AN,
    output wire [3:0]  VGA_R,
    output wire [3:0]  VGA_G,
    output wire [3:0]  VGA_B,
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire        AUD_PWM,
    output wire        AUD_SD
);
    wire clk = CLK100MHZ;

    //--------------------------------------------------------------------------
    // reset, switch and button synchronization
    //--------------------------------------------------------------------------
    wire rstn_s;
    sync_ff #(1) u_rst_sync (clk, CPU_RESETN, rstn_s);
    wire rst = ~rstn_s;

    wire [4:0] sw;
    sync_ff #(5) u_sw_sync (clk, SW, sw);
    wire       sw_not = sw[0];
    wire [1:0] sel    = {sw[3], sw[2]};   // A, B (select of both 4:1 MUX)
    wire       csel   = sw[1];            // C (select of the 2:1 MUX)

    wire [3:0] btn_s;
    sync_ff #(4) u_btn_sync (clk, {BTNC, BTNU, BTNL, BTNR}, btn_s);

    //--------------------------------------------------------------------------
    // enable pulses
    //--------------------------------------------------------------------------
    wire en25, en1m, en1k;
    clk_en #(DIV_1M, DIV_1K) u_clk_en (clk, rst, en25, en1m, en1k);

    //--------------------------------------------------------------------------
    // 4 buttons and SW4: debounce -> onepulse
    //--------------------------------------------------------------------------
    wire bc_db, bu_db, bl_db, br_db, s4_db;
    wire bc, bu, bl, br, s4;

    debounce #(DB_STABLE) u_db_c (clk, rst, en1k, btn_s[3], bc_db);
    debounce #(DB_STABLE) u_db_u (clk, rst, en1k, btn_s[2], bu_db);
    debounce #(DB_STABLE) u_db_l (clk, rst, en1k, btn_s[1], bl_db);
    debounce #(DB_STABLE) u_db_r (clk, rst, en1k, btn_s[0], br_db);
    debounce #(DB_STABLE) u_db_s (clk, rst, en1k, sw[4],    s4_db);

    onepulse u_op_c (clk, rst, bc_db, bc);
    onepulse u_op_u (clk, rst, bu_db, bu);
    onepulse u_op_l (clk, rst, bl_db, bl);
    onepulse u_op_r (clk, rst, br_db, br);
    onepulse u_op_s (clk, rst, s4_db, s4);

    //--------------------------------------------------------------------------
    // control FSM
    //   'go' = submit / next screen. BTNC always works; SW4 works in level 2.
    //--------------------------------------------------------------------------
    wire [3:0] state;
    wire       game_clr, clr_round, ans_edit;
    wire       score_add, life_dec, upd_best, q_adv;
    wire [1:0] snd_sel;
    wire       ans_ok, match, last_q, lives_zero;
    wire [1:0] level, lives;
    wire       go = bc | ((level == 2'd2) & s4);

    control_fsm u_fsm (
        clk, rst, go, ans_ok, match, last_q, lives_zero,
        state, game_clr, clr_round, ans_edit,
        score_add, life_dec, upd_best, q_adv, snd_sel
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
    // level 1 : player's gate and truth tables
    //--------------------------------------------------------------------------
    wire [2:0] a_g1;
    wire       gate_set;
    answer_reg u_ans (clk, rst, clr_round, ans_edit, bu, bl, br, sw_not, a_g1, gate_set);

    wire [3:0] hid_val, ans_val;
    kmap_val u_hid   (h_g1, hid_val);
    kmap_val u_ans_v (a_g1, ans_val);

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
    assign match  = (level == 2'd1) ? (hid_val == ans_val) : (mux_out == tgt);

    //--------------------------------------------------------------------------
    // score -> decimal
    //--------------------------------------------------------------------------
    wire [11:0] bcd_score, bcd_best, bcd_pts;
    bin2bcd #(10) u_bcd_score (score, bcd_score);
    bin2bcd #(10) u_bcd_best  (best,  bcd_best);
    bin2bcd #(10) u_bcd_pts   ({2'b00, pts}, bcd_pts);

    //--------------------------------------------------------------------------
    // 7-segment : [7] level [6] question no. [3] lives [2:0] score
    //--------------------------------------------------------------------------
    wire [31:0] seg_digits = { {2'b00, level},              // AN7
                               {1'b0, qnum} + 4'd1,         // AN6
                               4'd0,                        // AN5 (blank)
                               4'd0,                        // AN4 (blank)
                               {2'b00, lives},              // AN3
                               bcd_score[11:8],             // AN2
                               bcd_score[7:4],              // AN1
                               bcd_score[3:0] };            // AN0
    wire [6:0] seg_n;
    seg7_driver u_seg (
        clk, rst, en1k, seg_digits,
        8'b1000_1000,               // dp_mask
        8'b0011_0000,               // blank AN5, AN4
        AN, seg_n, DP
    );
    assign {CG, CF, CE, CD, CC, CB, CA} = seg_n;

    //--------------------------------------------------------------------------
    // VGA
    //--------------------------------------------------------------------------
    wire [9:0] vx, vy;
    wire       v_hs, v_vs, v_active;
    vga_sync u_vga (clk, rst, en25, vx, vy, v_hs, v_vs, v_active);

    renderer u_render (
        clk, rst, en25, vx, vy, v_hs, v_vs, v_active,
        state, level, qnum, lives, lives_zero,
        bcd_score[11:8], bcd_score[7:4], bcd_score[3:0],
        bcd_best[11:8],  bcd_best[7:4],  bcd_best[3:0],
        bcd_pts[11:8],   bcd_pts[7:4],   bcd_pts[3:0],
        a_g1, h_g1,
        (state == 4'd7),            // reveal the hidden gate after a correct answer
        hid_val,
        d0, d1, d2, d3, e0, e1, e2, e3, tgt, sel, csel, mode8, mux_out,
        VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS
    );

    //--------------------------------------------------------------------------
    // LED, RGB LED, sound
    //--------------------------------------------------------------------------
    assign LED[2:0]  = (lives == 2'd3) ? 3'b111 : (lives == 2'd2) ? 3'b011 :
                       (lives == 2'd1) ? 3'b001 : 3'b000;
    assign LED[3]    = (state == 4'd5) & ans_ok;
    assign LED[15:4] = 12'd0;

    status_led u_status (clk, rst, state, lives_zero, LED16_R, LED16_G, LED16_B);

    sound_gen #(NOTE_MS) u_sound (clk, rst, en1m, en1k, snd_sel, AUD_PWM, AUD_SD);
endmodule
