`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// puzzle_rom : FIXED questions (5 in total). The question number selects the puzzle.
//
//   Level 1 (Q1-Q3) : hidden gate F = G1(A,B). Gate codes: AND 000, OR 001, XOR 010, NOR 101
//       Q1 : AND
//       Q2 : NOR   (OR with the NOT switch)
//       Q3 : XOR
//   Level 2 (Q4-Q5) : MUX puzzles, the player sets the three select signals A, B, C
//       so that the output equals the target number (A is the high bit).
//       Q4 : one 8:1 MUX, inputs D0..D7 (stored in d0..d3, e0..e3), input number = {A,B,C}
//            D = 3 8 5 1 7 2 9 4, target 9  ->  A B C = 1 1 0   (D6)
//       Q5 : two 4:1 MUX (same select A,B) feeding one 2:1 MUX (select C)
//            upper MUX D0..D3, lower MUX E0..E3, output = C ? lower[AB] : upper[AB]
//            D = 6 2 8 5, E = 1 4 7 3, target 4  ->  A B C = 0 1 1   (E1)
//------------------------------------------------------------------------------
module puzzle_rom (
    input  wire [2:0] qnum,      // 0..4
    output reg  [2:0] g1,        // level 1 : hidden gate code
    output reg  [3:0] d0,        // level 2 : upper MUX data inputs
    output reg  [3:0] d1,
    output reg  [3:0] d2,
    output reg  [3:0] d3,
    output reg  [3:0] e0,        // level 2 : lower MUX data inputs
    output reg  [3:0] e1,
    output reg  [3:0] e2,
    output reg  [3:0] e3,
    output reg  [3:0] tgt        // level 2 : target number
);
    always @* begin
        g1 = 3'b000;
        d0 = 4'd0; d1 = 4'd0; d2 = 4'd0; d3 = 4'd0;
        e0 = 4'd0; e1 = 4'd0; e2 = 4'd0; e3 = 4'd0;
        tgt = 4'd0;
        case (qnum)
            3'd0:    g1 = 3'b000;                                         // AND
            3'd1:    g1 = 3'b101;                                         // NOR
            3'd2:    g1 = 3'b010;                                         // XOR
            3'd3:    begin
                d0 = 4'd3; d1 = 4'd8; d2 = 4'd5; d3 = 4'd1;
                e0 = 4'd7; e1 = 4'd2; e2 = 4'd9; e3 = 4'd4;
                tgt = 4'd9;
            end
            default: begin
                d0 = 4'd6; d1 = 4'd2; d2 = 4'd8; d3 = 4'd5;
                e0 = 4'd1; e1 = 4'd4; e2 = 4'd7; e3 = 4'd3;
                tgt = 4'd4;
            end
        endcase
    end
endmodule
