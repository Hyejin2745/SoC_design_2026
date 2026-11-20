`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// control_fsm : overall game flow (Moore machine)
//   TITLE -> INIT -> ANSWER -> CORRECT -> (INIT | END)
//                           -> WRONG   -> (ANSWER | END)
//   END -> TITLE
//   bc is a 1-clock pulse of the centre button.
//   In ANSWER the centre button submits, but only when every gate has been set (ans_ok).
//   'match' = the player's circuit has the same truth table as the hidden circuit.
//   State numbers are shared with text_gen / shape_gen / status_led (2,3,4,6 are unused).
//   Signals that must change only once (score, lives) are 1 only in the first
//   clock after entering the state (the 'entering' flag).
//------------------------------------------------------------------------------
module control_fsm (
    input  wire       clk,
    input  wire       rst,
    input  wire       bc,
    input  wire       ans_ok,
    input  wire       match,
    input  wire       last_q,
    input  wire       lives_zero,
    output reg  [3:0] state,
    output wire       game_clr,
    output wire       clr_round,
    output wire       ans_edit,
    output wire       score_add,
    output wire       life_dec,
    output wire       upd_best,
    output reg        q_adv,
    output reg  [1:0] snd_sel
);
    localparam S_TITLE   = 4'd0,
               S_INIT    = 4'd1,
               S_ANSWER  = 4'd5,
               S_CORRECT = 4'd7,
               S_WRONG   = 4'd8,
               S_END     = 4'd9;

    reg [3:0] next;
    reg       entering;

    always @* begin
        next = state;
        case (state)
            S_TITLE:   if (bc) next = S_INIT;
            S_INIT:    next = S_ANSWER;
            S_ANSWER:  if (bc && ans_ok) next = match ? S_CORRECT : S_WRONG;
            S_CORRECT: if (bc) next = last_q ? S_END : S_INIT;
            S_WRONG:   if (bc) next = lives_zero ? S_END : S_ANSWER;
            S_END:     if (bc) next = S_TITLE;
            default:   next = S_TITLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_TITLE;
            entering <= 1'b0;
            q_adv    <= 1'b0;
        end else begin
            state    <= next;
            entering <= (next != state);
            q_adv    <= (state == S_CORRECT) && bc && !last_q;
        end
    end

    assign game_clr  = (state == S_TITLE);
    assign clr_round = (state == S_INIT);
    assign ans_edit  = (state == S_ANSWER);

    assign score_add = (state == S_CORRECT) && entering;
    assign life_dec  = (state == S_WRONG)   && entering;
    assign upd_best  = (state == S_END)     && entering;

    // sound: 1 correct, 2 wrong / game over, 3 clear
    always @* begin
        case (state)
            S_CORRECT: snd_sel = 2'd1;
            S_WRONG:   snd_sel = 2'd2;
            S_END:     snd_sel = lives_zero ? 2'd2 : 2'd3;
            default:   snd_sel = 2'd0;
        endcase
    end
endmodule
