`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// score_unit : score, lives, question number / level, best score
//   One game = 5 fixed questions (qnum 0~4): Q1-Q3 are level 1 (gate), Q4-Q5 are level 2 (MUX). 3 lives.
//   Points for a correct answer:
//     level 1 : 100 with no wrong try on this question, 70 after one wrong try, 40 after two or more
//     level 2 : always 100
//------------------------------------------------------------------------------
module score_unit (
    input  wire       clk,
    input  wire       rst,
    input  wire       game_clr,    // title: clear score, lives and question number
    input  wire       score_add,   // clock of entering the correct screen
    input  wire       life_dec,    // clock of entering the wrong screen
    input  wire       q_adv,       // go to the next question
    input  wire       upd_best,    // clock of entering the end screen
    output reg  [2:0] qnum,        // 0~4
    output wire [1:0] level,       // 1~2
    output reg  [1:0] lives,       // 0~3
    output reg  [9:0] score,
    output reg  [9:0] best,
    output wire [7:0] pts,
    output wire       lives_zero,
    output wire       last_q
);
    reg [1:0] wrongs;              // wrong tries on the current question (saturates at 3)

    assign level      = (qnum < 3'd3) ? 2'd1 : 2'd2;
    assign pts        = (level == 2'd2)  ? 8'd100 :
                        (wrongs == 2'd0) ? 8'd100 :
                        (wrongs == 2'd1) ? 8'd70  : 8'd40;
    assign lives_zero = (lives == 2'd0);
    assign last_q     = (qnum == 3'd4);

    always @(posedge clk) begin
        if (rst) begin
            qnum   <= 3'd0;
            lives  <= 2'd3;
            score  <= 10'd0;
            best   <= 10'd0;
            wrongs <= 2'd0;
        end else begin
            if (game_clr) begin
                qnum   <= 3'd0;
                lives  <= 2'd3;
                score  <= 10'd0;
                wrongs <= 2'd0;
            end else begin
                if (score_add)                  score <= score + {2'b00, pts};
                if (life_dec && lives != 2'd0)  lives <= lives - 2'd1;
                if (life_dec && wrongs != 2'd3) wrongs <= wrongs + 2'd1;
                if (q_adv) begin
                    if (qnum != 3'd4) qnum <= qnum + 3'd1;
                    wrongs <= 2'd0;
                end
            end
            if (upd_best && score > best) best <= score;
        end
    end
endmodule
