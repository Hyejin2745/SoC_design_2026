`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// text_gen : the character (ASCII) and colour attribute for cell (col,row) of the 80-column x 30-row text grid
//   There is no frame buffer, so the character is decided combinationally each time a coordinate comes in.
//   Only English text (digits, upper-case letters, symbols) is shown on the monitor.
//   attr : 0 white, 1 yellow, 2 green, 3 red, 4 light blue, 5 gray
//
//   Level 1 (questions 1-3) : K-map of a hidden gate, the player picks the gate (+ NOT switch)
//   Level 2 (questions 4-5) : Q4 one 8:1 MUX, Q5 two 4:1 MUX + one 2:1 MUX; the player sets A, B, C to output the target
//------------------------------------------------------------------------------
module text_gen (
    input  wire [6:0]  col,
    input  wire [4:0]  row,
    input  wire [3:0]  state,
    input  wire [1:0]  level,
    input  wire [2:0]  qnum,
    input  wire [1:0]  lives,
    input  wire        lives_zero,
    input  wire [3:0]  s2, s1, s0,      // score
    input  wire [3:0]  b2, b1, b0,      // best score
    input  wire [3:0]  p2, p1, p0,      // score of this question
    input  wire [2:0]  gcode,           // gate shown (player's gate, or hidden gate once correct); 111 = not set
    input  wire [3:0]  val,             // truth table of the hidden gate (K-map), val[{A,B}]
    input  wire [3:0]  d0, d1, d2, d3,  // upper 4:1 MUX data inputs
    input  wire [3:0]  e0, e1, e2, e3,  // lower 4:1 MUX data inputs
    input  wire [3:0]  tgt,             // target number
    input  wire [1:0]  sel,             // A, B (select of both 4:1 MUX)
    input  wire        csel,            // C (select of the 2:1 MUX, low bit of the 8:1 MUX)
    input  wire        mode8,           // 1 = single 8:1 MUX, 0 = 4:1 + 4:1 + 2:1
    input  wire [3:0]  mux_out,         // output of the 2:1 MUX
    output reg  [7:0]  ch,
    output reg  [2:0]  attr
);
    localparam S_TITLE = 4'd0, S_INIT = 4'd1, S_ANSWER = 4'd2,
               S_CORRECT = 4'd3, S_WRONG = 4'd4, S_END = 4'd5;

    // i-th character of s (string length L, blank when out of range)
    function [7:0] S;
        input [8*48-1:0] s;
        input integer    L;
        input integer    i;
        begin
            if (i >= 0 && i < L) S = s[8*(L-1-i) +: 8];
            else                 S = 8'h20;
        end
    endfunction

    function [7:0] dg;           // one digit -> ASCII
        input [3:0] d;
        dg = 8'h30 + {4'b0, d};
    endfunction

    function [7:0] bit_ch;
        input b;
        bit_ch = b ? 8'h31 : 8'h30;
    endfunction

    // gate name length / character (111 = not set -> '?')
    function integer glen;
        input [2:0] code;
        case (code)
            3'b000:  glen = 3;   // AND
            3'b001:  glen = 2;   // OR
            3'b010:  glen = 3;   // XOR
            3'b100:  glen = 4;   // NAND
            3'b101:  glen = 3;   // NOR
            3'b110:  glen = 4;   // XNOR
            default: glen = 1;   // ?
        endcase
    endfunction

    function [7:0] gch;
        input [2:0]   code;
        input integer i;
        case (code)
            3'b000:  gch = S("AND",  3, i);
            3'b001:  gch = S("OR",   2, i);
            3'b010:  gch = S("XOR",  3, i);
            3'b100:  gch = S("NAND", 4, i);
            3'b101:  gch = S("NOR",  3, i);
            3'b110:  gch = S("XNOR", 4, i);
            default: gch = S("?",    1, i);
        endcase
    endfunction

    // MUX data input value by index
    function [3:0] dval;
        input [1:0] k;
        case (k)
            2'd0:    dval = d0;
            2'd1:    dval = d1;
            2'd2:    dval = d2;
            default: dval = d3;
        endcase
    endfunction

    // lower MUX data input value by index
    function [3:0] eval_;
        input [1:0] k;
        case (k)
            2'd0:    eval_ = e0;
            2'd1:    eval_ = e1;
            2'd2:    eval_ = e2;
            default: eval_ = e3;
        endcase
    endfunction

    integer c, r;
    integer ci, ri, coff;
    reg       game_view;
    reg       lv1;
    reg       rev2;          // level 2: show the chosen input / output only on the result screens
    reg [1:0] k;

    always @* begin
        c = col;
        r = row;
        ch = 8'h20;
        attr = 3'd0;
        ci = 0; ri = 0; coff = 0;
        k = 2'd0;

        lv1 = (level == 2'd1);
        rev2 = (state == S_CORRECT) || (state == S_WRONG);
        game_view = (state >= S_INIT) && (state <= S_WRONG);

        //======================================================================
        // title screen
        //======================================================================
        if (state == S_TITLE) begin
            if (r == 8) begin
                attr = 3'd4;
                if (c >= 30 && c < 48) ch = S("KARNAUGH GATE QUIZ", 18, c - 30);
            end else if (r == 11) begin
                if (c >= 24 && c < 51) ch = S("LOGIC GATES AND THE 4:1 MUX", 27, c - 24);
            end else if (r == 13) begin
                attr = 3'd5;
                if (c >= 20 && c < 55) ch = S("LEVEL 1 FIND THE GATE   LEVEL 2 MUX", 35, c - 20);
            end else if (r == 16) begin
                attr = 3'd1;
                if (c >= 26 && c < 54) ch = S("PRESS CENTER BUTTON TO START", 28, c - 26);
            end else if (r == 18) begin
                if (c >= 32 && c < 42)      ch = S("HIGH SCORE", 10, c - 32);
                else if (c == 43)           ch = dg(b2);
                else if (c == 44)           ch = dg(b1);
                else if (c == 45)           ch = dg(b0);
            end

        //======================================================================
        // end screen (STAGE CLEAR / GAME OVER)
        //======================================================================
        end else if (state == S_END) begin
            if (r == 9) begin
                if (lives_zero) begin
                    attr = 3'd3;
                    if (c >= 35 && c < 44) ch = S("GAME OVER", 9, c - 35);
                end else begin
                    attr = 3'd2;
                    if (c >= 34 && c < 46) ch = S("STAGE CLEAR!", 12, c - 34);
                end
            end else if (r == 12) begin
                if (c >= 30 && c < 41)      ch = S("FINAL SCORE", 11, c - 30);
                else if (c == 43)           ch = dg(s2);
                else if (c == 44)           ch = dg(s1);
                else if (c == 45)           ch = dg(s0);
            end else if (r == 14) begin
                attr = 3'd1;
                if (c >= 30 && c < 40)      ch = S("HIGH SCORE", 10, c - 30);
                else if (c == 43)           ch = dg(b2);
                else if (c == 44)           ch = dg(b1);
                else if (c == 45)           ch = dg(b0);
            end else if (r == 18) begin
                attr = 3'd5;
                if (c >= 21 && c < 59) ch = S("PRESS CENTER BUTTON TO RETURN TO TITLE", 38, c - 21);
            end

        //======================================================================
        // game screen
        //======================================================================
        end else if (game_view) begin
            //---------------- top line info
            if (r == 1) begin
                if (c >= 2 && c < 20) begin
                    ch = S("KARNAUGH GATE QUIZ", 18, c - 2);
                    attr = 3'd4;
                end else if (c >= 24 && c < 31) begin
                    ch = (c == 30) ? dg({2'b00, level}) : S("LEVEL ", 6, c - 24);
                end else if (c >= 34 && c < 38) begin
                    case (c)
                        34:      ch = "Q";
                        35:      ch = dg({1'b0, qnum} + 4'd1);
                        36:      ch = "/";
                        default: ch = "5";
                    endcase
                end else if (c >= 42 && c < 49) begin
                    ch = (c == 48) ? dg({2'b00, lives}) : S("LIVES ", 6, c - 42);
                    if (c == 48) attr = 3'd3;
                end else if (c >= 54 && c < 63) begin
                    if (c >= 60)       ch = (c == 60) ? dg(s2) : (c == 61) ? dg(s1) : dg(s0);
                    else               ch = S("SCORE ", 6, c - 54);
                    if (c >= 60) attr = 3'd1;
                end else if (c >= 66 && c < 74) begin
                    if (c >= 71)       ch = (c == 71) ? dg(b2) : (c == 72) ? dg(b1) : dg(b0);
                    else               ch = S("BEST ", 5, c - 66);
                    if (c >= 71) attr = 3'd5;
                end
            end

            //==================================================================
            // LEVEL 1 : gate symbol (drawn by shape_gen) + K-map
            //==================================================================
            if (lv1) begin
                if (r == 2 && c >= 2 && c < 40) begin
                    attr = 3'd5;
                    ch = S("READ THE K-MAP AND FIND THE GATE", 32, c - 2);
                end

                // input names
                if (c == 4) begin
                    if (r == 7)       ch = "A";
                    else if (r == 10) ch = "B";
                end
                if (c == 38 && r == 9) ch = "F";

                // caption and gate name under the symbol
                if (r == 5 && c >= 14 && c < 23) begin
                    attr = 3'd4;
                    ch = (state == S_CORRECT) ? S("THE  GATE", 9, c - 14) : S("YOUR GATE", 9, c - 14);
                end
                if (r == 12 && c >= 14 && c < 22) begin
                    attr = 3'd1;
                    ch = gch(gcode, c - (14 + ((8 - glen(gcode)) >> 1)));
                end

                // K-map
                if (r == 4 && c >= 44 && c < 61) begin
                    ch = S("KARNAUGH MAP OF F", 17, c - 44);
                    attr = 3'd4;
                end
                if (r == 6 && c >= 55 && c < 64) begin
                    ci = (c >= 60) ? 1 : 0;
                    coff = c - 54 - 6 * ci;
                    if (coff >= 1 && coff < 4)
                        ch = (coff == 1) ? "B" : (coff == 2) ? "=" : bit_ch(ci[0]);
                    attr = 3'd1;
                end
                if ((r == 8 || r == 11) && c >= 49 && c < 52) begin
                    ri = (r == 11) ? 1 : 0;
                    ch = (c == 49) ? "A" : (c == 50) ? "=" : bit_ch(ri[0]);
                    attr = 3'd1;
                end
                if ((r == 8 || r == 11) && (c == 57 || c == 63)) begin
                    ri = (r == 11) ? 1 : 0;
                    ci = (c == 63) ? 1 : 0;
                    ch = bit_ch(val[{ri[0], ci[0]}]);
                end

                // message area at the bottom
                case (state)
                    S_ANSWER: begin
                        if (r == 24 && c >= 2 && c < 40) begin
                            ch = S("BUTTONS  UP=AND  LEFT=OR  RIGHT=XOR", 35, c - 2);
                            attr = 3'd4;
                        end
                        if (r == 25 && c >= 2 && c < 40) begin
                            ch = S("SW0 UP = NOT  (INVERTS THE GATE)", 32, c - 2);
                            attr = 3'd4;
                        end
                        if (r == 26) begin
                            if (c >= 2 && c < 14) ch = S("YOUR GATE = ", 12, c - 2);
                            else if (c >= 14 && c < 18) begin
                                ch = gch(gcode, c - 14);
                                attr = 3'd1;
                            end
                        end
                        if (r == 28 && c >= 2 && c < 50) begin
                            attr = 3'd5;
                            ch = S("CENTER = SUBMIT  (PICK A GATE FIRST)", 36, c - 2);
                        end
                    end

                    S_CORRECT: begin
                        if (r == 25) begin
                            attr = 3'd2;
                            if (c >= 2 && c < 10)       ch = S("CORRECT!", 8, c - 2);
                            else if (c == 13)           ch = "+";
                            else if (c == 14)           ch = (p2 == 4'd0) ? 8'h20 : dg(p2);
                            else if (c == 15)           ch = dg(p1);
                            else if (c == 16)           ch = dg(p0);
                            else if (c >= 18 && c < 24) ch = S("POINTS", 6, c - 18);
                        end
                        if (r == 26 && c >= 2 && c < 40)
                            ch = S("THE HIDDEN GATE IS SHOWN ABOVE", 30, c - 2);
                        if (r == 28 && c >= 2 && c < 40) begin
                            attr = 3'd5;
                            ch = S("PRESS CENTER BUTTON TO CONTINUE", 31, c - 2);
                        end
                    end

                    S_WRONG: begin
                        if (r == 25) begin
                            attr = 3'd3;
                            if (c >= 2 && c < 8)        ch = S("WRONG!", 6, c - 2);
                            else if (c >= 11 && c < 44) ch = S("YOUR GATE GIVES A DIFFERENT K-MAP", 33, c - 11);
                        end
                        if (r == 28) begin
                            attr = 3'd5;
                            if (lives_zero) begin
                                if (c >= 2 && c < 40) ch = S("NO LIVES LEFT. PRESS CENTER BUTTON", 34, c - 2);
                            end else begin
                                if (c >= 2 && c < 12)       ch = S("LIVES LEFT", 10, c - 2);
                                else if (c == 13)           ch = dg({2'b00, lives});
                                else if (c >= 16 && c < 50) ch = S("PRESS CENTER BUTTON TO TRY AGAIN", 32, c - 16);
                            end
                        end
                    end

                    default: ;
                endcase

            //==================================================================
            // LEVEL 2 : two 4:1 MUX (shared A,B) + one 2:1 MUX (C)
            //==================================================================
            end else begin
                if (r == 2 && c >= 2 && c < 50) begin
                    attr = 3'd5;
                    ch = S("SELECT THE INPUT THAT GIVES THE TARGET", 38, c - 2);
                end

                // goal
                if (r == 4) begin
                    if (c >= 4 && c < 28)       ch = S("GOAL: OUTPUT THE NUMBER ", 24, c - 4);
                    else if (c == 28) begin ch = dg(tgt); attr = 3'd1; end
                end

                // select names above the upper MUX (4:1 + 4:1 + 2:1 only)
                if (!mode8 && r == 5) begin
                    if (c == 32)      begin ch = "A"; attr = 3'd4; end
                    else if (c == 36) begin ch = "B"; attr = 3'd4; end
                end

                // data inputs on rows 6, 8, ..., 20.
                //   8:1 MUX     : D0..D7, the input chosen by {A,B,C} is green
                //   4:1+4:1+2:1 : D0..D3 (rows 6-12), E0..E3 (rows 14-20), the input chosen by A,B is green in both
                if ((r == 6 || r == 8 || r == 10 || r == 12 ||
                     r == 14 || r == 16 || r == 18 || r == 20) && c >= 6 && c < 12) begin
                    ri = (r - 6) / 2;
                    k  = ri[1:0];
                    case (c)
                        6:       ch = (mode8 || r < 14) ? "D" : "E";
                        7:       ch = mode8 ? dg(ri[3:0]) : dg({2'b00, k});
                        9:       ch = "=";
                        11:      ch = (r < 14) ? dg(dval(k)) : dg(eval_(k));
                        default: ch = 8'h20;
                    endcase
                    attr = !rev2 ? 3'd0 :
                           mode8 ? ((ri == {sel, csel}) ? 3'd2 : 3'd0)
                                 : ((k == sel)          ? 3'd2 : 3'd0);
                end

                // MUX labels
                if (mode8) begin
                    if (r == 12 && c >= 32 && c < 35) ch = S("MUX", 3, c - 32);
                    if (r == 13 && c >= 32 && c < 35) ch = S("8:1", 3, c - 32);
                end else begin
                    if (r == 8  && c >= 32 && c < 35) ch = S("MUX", 3, c - 32);
                    if (r == 9  && c >= 32 && c < 35) ch = S("4:1", 3, c - 32);
                    if (r == 16 && c >= 32 && c < 35) ch = S("MUX", 3, c - 32);
                    if (r == 17 && c >= 32 && c < 35) ch = S("4:1", 3, c - 32);
                    if (r == 12 && c >= 49 && c < 52) ch = S("MUX", 3, c - 49);
                    if (r == 13 && c >= 49 && c < 52) ch = S("2:1", 3, c - 49);
                end

                // output
                if (r == 13 && c >= 62 && c < 69) begin
                    ch = S("OUT = ", 6, c - 62);
                    if (c == 68) begin ch = rev2 ? dg(mux_out) : "?"; attr = rev2 ? 3'd1 : 3'd0; end
                end

                // select values under the MUX
                if (r == 22) begin
                    if (mode8) begin
                        if (c >= 30 && c < 33) begin
                            ch = (c == 30) ? "A" : (c == 31) ? "=" : bit_ch(sel[1]);
                            attr = 3'd0;
                        end else if (c >= 33 && c < 36) begin
                            ch = (c == 33) ? "B" : (c == 34) ? "=" : bit_ch(sel[0]);
                            attr = 3'd0;
                        end else if (c >= 36 && c < 39) begin
                            ch = (c == 36) ? "C" : (c == 37) ? "=" : bit_ch(csel);
                            attr = 3'd0;
                        end
                    end else begin
                        if (c >= 31 && c < 35) begin
                            ch = (c == 31) ? "A" : (c == 32) ? "=" : (c == 33) ? bit_ch(sel[1]) : 8'h20;
                            attr = 3'd0;
                        end else if (c >= 35 && c < 38) begin
                            ch = (c == 35) ? "B" : (c == 36) ? "=" : bit_ch(sel[0]);
                            attr = 3'd0;
                        end else if (c >= 51 && c < 54) begin
                            ch = (c == 51) ? "C" : (c == 52) ? "=" : bit_ch(csel);
                            attr = 3'd0;
                        end
                    end
                end

                // message area at the bottom
                case (state)
                    S_ANSWER: begin
                        if (r == 24 && c >= 2 && c < 44) begin
                            ch = S("SW3 = A    SW2 = B    SW1 = C", 29, c - 2);
                            attr = 3'd4;
                        end
                        if (r == 25) begin
                            if (c >= 2 && c < 8)         ch = S("ABC = ", 6, c - 2);
                            else if (c == 8)  ch = bit_ch(sel[1]);
                            else if (c == 9)  ch = bit_ch(sel[0]);
                            else if (c == 10) ch = bit_ch(csel);
                            else if (c >= 14 && c < 24)  ch = S("OUTPUT IS ", 10, c - 14);
                            else if (c == 24) ch = "?";
                        end
                        if (r == 27 && mode8 && c >= 2 && c < 50) begin
                            attr = 3'd5;
                            ch = S("ABC IS THE INPUT NUMBER IN BINARY (A = HIGH BIT)", 48, c - 2);
                        end
                        if (r == 28 && c >= 2 && c < 50) begin
                            attr = 3'd5;
                            ch = S("RAISE SW4 TO SUBMIT  (OR CENTER BUTTON)", 39, c - 2);
                        end
                    end

                    S_CORRECT: begin
                        if (r == 25) begin
                            attr = 3'd2;
                            if (c >= 2 && c < 10)       ch = S("CORRECT!", 8, c - 2);
                            else if (c == 13)           ch = "+";
                            else if (c == 14)           ch = (p2 == 4'd0) ? 8'h20 : dg(p2);
                            else if (c == 15)           ch = dg(p1);
                            else if (c == 16)           ch = dg(p0);
                            else if (c >= 18 && c < 24) ch = S("POINTS", 6, c - 18);
                        end
                        if (r == 26 && c >= 2 && c < 40) begin
                            if (c < 23) ch = S("THE SELECTED INPUT IS", 21, c - 2);
                            else if (c == 24) ch = (mode8 || !csel) ? "D" : "E";
                            else if (c == 25) ch = mode8 ? dg({1'b0, sel, csel}) : dg({2'b00, sel});
                        end
                        if (r == 28 && c >= 2 && c < 52) begin
                            attr = 3'd5;
                            ch = S("RAISE SW4 TO CONTINUE  (OR CENTER BUTTON)", 41, c - 2);
                        end
                    end

                    S_WRONG: begin
                        if (r == 25) begin
                            attr = 3'd3;
                            if (c >= 2 && c < 8)        ch = S("WRONG!", 6, c - 2);
                            else if (c >= 11 && c < 40) ch = S("THE OUTPUT IS NOT THE TARGET", 28, c - 11);
                        end
                        if (r == 28) begin
                            attr = 3'd5;
                            if (lives_zero) begin
                                if (c >= 2 && c < 40) ch = S("NO LIVES LEFT. PRESS CENTER BUTTON", 34, c - 2);
                            end else begin
                                if (c >= 2 && c < 12)       ch = S("LIVES LEFT", 10, c - 2);
                                else if (c == 13)           ch = dg({2'b00, lives});
                                else if (c >= 16 && c < 58) ch = S("RAISE SW4 TO TRY AGAIN  (OR CENTER BUTTON)", 42, c - 16);
                            end
                        end
                    end

                    default: ;
                endcase
            end
        end
    end
endmodule
