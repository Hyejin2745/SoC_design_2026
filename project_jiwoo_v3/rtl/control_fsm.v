`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// control_fsm : overall game flow, Moore state machine (same template as Lab5 MooreStateM.v)
//   TITLE(0) -> INIT(1) -> ANSWER(2) -> CORRECT(3) -> (INIT | END)
//                                    -> WRONG(4)   -> (ANSWER | END)
//   END(5) -> TITLE
//   bc is a 1-clock pulse of the submit / next button (BTNC).
//   In ANSWER bc submits, but only when the answer is complete (ans_ok).
//   'match' = the player's answer is the right one.
//   State numbers are shared with text_gen / shape_gen / top_board.
//   score_add, life_dec, upd_best must change only once, so they are 1 only in the
//   first clock after entering the state (the 'entering' flag).
//------------------------------------------------------------------------------
module control_fsm (
    input  wire       clk,
    input  wire       rst,
    input  wire       bc,
    input  wire       ans_ok,
    input  wire       match,
    input  wire       last_q,
    input  wire       lives_zero,
    output wire [3:0] state,
    output reg        game_clr,
    output reg        clr_round,
    output reg        ans_edit,
    output wire       score_add,
    output wire       life_dec,
    output wire       upd_best,
    output reg        q_adv
);
    localparam [3:0] S_TITLE   = 4'd0,
                     S_INIT    = 4'd1,
                     S_ANSWER  = 4'd2,
                     S_CORRECT = 4'd3,
                     S_WRONG   = 4'd4,
                     S_END     = 4'd5;

    reg [3:0] preState, nextState;
    reg       entering;

    always @ (posedge clk) begin //sequential
        if (!rst) begin //Synchronous Reset
            preState <= S_TITLE;
            entering <= 1'b0;
            q_adv    <= 1'b0;
        end
        else begin
            preState <= nextState;
            entering <= (nextState != preState);
            q_adv    <= (preState == S_CORRECT) && bc && !last_q;
        end
    end

    always @(*) begin //combinational: next state and Moore outputs
        nextState = preState;
        game_clr  = 1'b0;
        clr_round = 1'b0;
        ans_edit  = 1'b0;
        case (preState)
            S_TITLE: begin
                game_clr = 1'b1;
                if (bc) nextState = S_INIT;
            end
            S_INIT: begin
                clr_round = 1'b1;
                nextState = S_ANSWER;
            end
            S_ANSWER: begin
                ans_edit = 1'b1;
                if (bc && ans_ok) nextState = match ? S_CORRECT : S_WRONG;
            end
            S_CORRECT: begin
                if (bc) nextState = last_q ? S_END : S_INIT;
            end
            S_WRONG: begin
                if (bc) nextState = lives_zero ? S_END : S_ANSWER;
            end
            S_END: begin
                if (bc) nextState = S_TITLE;
            end
            default: nextState = S_TITLE;
        endcase
    end

    assign state = preState;

    assign score_add = (preState == S_CORRECT) && entering;
    assign life_dec  = (preState == S_WRONG)   && entering;
    assign upd_best  = (preState == S_END)     && entering;
endmodule
