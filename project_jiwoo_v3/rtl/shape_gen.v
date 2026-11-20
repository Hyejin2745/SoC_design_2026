`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// shape_gen : shape layer. For each coordinate (x,y) it decides the colour (RGB 4-4-4).
//   Level 1 : gate symbol (AND / OR / XOR, with a NOT bubble) in x 112~176, y 104~184,
//             input wires A, B, output wire F and the 2x2 K-map at x 432~528, y 112~208
//   Level 2 : Q4 one 8:1 MUX (select A,B,C); Q5 two 4:1 MUX (shared select A,B) and one 2:1 MUX (select C);
//             the wires on the path from the selected input to the output are yellow
//   The text layer (text_gen) is overlaid on top of this in renderer.
//------------------------------------------------------------------------------
module shape_gen (
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire [3:0]  state,
    input  wire [1:0]  level,
    input  wire [2:0]  gcode,       // gate symbol to draw (111 = none yet)
    input  wire [3:0]  val,         // K-map, val[{A,B}]
    input  wire [1:0]  sel,         // A, B
    input  wire        csel,        // C
    input  wire        mode8,       // 1 = single 8:1 MUX, 0 = 4:1 + 4:1 + 2:1
    output reg  [11:0] rgb
);
    localparam S_TITLE = 4'd0, S_INIT = 4'd1,
               S_CORRECT = 4'd7, S_WRONG = 4'd8, S_END = 4'd9;

    localparam [11:0] C_BG     = 12'h112,
                      C_PANEL  = 12'h000,
                      C_WHITE  = 12'hFFF,
                      C_GRAY   = 12'h777,
                      C_YELLOW = 12'hFE0,
                      C_GREEN  = 12'h0D2,
                      C_RED    = 12'hF22,
                      C_CYAN   = 12'h0CF,
                      C_BOXBG  = 12'h235,
                      C_CELL0  = 12'h336,
                      C_CELL1  = 12'h162;

    // horizontal / vertical wire segments (2 pixels thick)
    function hseg;
        input [9:0] px, py, x0, x1, yy;
        hseg = (px >= x0) && (px < x1) && (py >= yy) && (py < yy + 10'd2);
    endfunction

    function vseg;
        input [9:0] px, py, xx, y0, y1;
        vseg = (py >= y0) && (py < y1) && (px >= xx) && (px < xx + 10'd2);
    endfunction

    function inbox;
        input [9:0] px, py, x0, y0, x1, y1;
        inbox = (px >= x0) && (px < x1) && (py >= y0) && (py < y1);
    endfunction

    // box outline (thickness t)
    function boxedge;
        input [9:0] px, py, x0, y0, x1, y1, t;
        boxedge = inbox(px, py, x0, y0, x1, y1) &&
                  !inbox(px, py, x0 + t, y0 + t, x1 - t, y1 - t);
    endfunction

    wire game_view = (state >= S_INIT) && (state <= S_WRONG);
    // level 2: the chosen path is highlighted only on the result screens, never while the player is trying
    wire rev2      = (state == S_CORRECT) || (state == S_WRONG);
    wire lv1       = (level == 2'd1);

    //==========================================================================
    // level 1 : gate symbol
    //==========================================================================
    wire        gset = (gcode != 3'b111);
    wire        ginv = gcode[2];
    wire [1:0]  gkind = (gcode[1:0] == 2'b11) ? 2'd0 : gcode[1:0];

    wire        in_sym = inbox(x, y, 10'd112, 10'd104, 10'd176, 10'd184);
    wire [9:0]  rel_x  = x - 10'd112;
    wire [9:0]  rel_y  = y - 10'd104;
    wire [5:0]  s_row  = rel_y[6:1];
    wire [4:0]  s_col  = rel_x[5:1];
    wire [31:0] s_bits;
    wire [4:0]  lead_a, lead_b;
    gate_sprite u_spr (gkind, s_row, s_bits, lead_a, lead_b);

    wire sym_on  = in_sym && gset && s_bits[5'd31 - s_col];
    wire sym_box = !gset && boxedge(x, y, 10'd112, 10'd104, 10'd176, 10'd184, 10'd2);

    // input wires run up to the symbol, output wire F leaves it
    wire [9:0] xa_end = gset ? (10'd112 + {4'b0000, lead_a, 1'b0}) : 10'd112;
    wire [9:0] xb_end = gset ? (10'd112 + {4'b0000, lead_b, 1'b0}) : 10'd112;
    wire w1_a = hseg(x, y, 10'd56, xa_end, 10'd120);
    wire w1_b = hseg(x, y, 10'd56, xb_end, 10'd168);
    wire w1_f = hseg(x, y, 10'd176, 10'd304, 10'd144);      // always drawn, even before a gate is chosen

    // NOT bubble at the gate output
    wire signed [10:0] dx = $signed({1'b0, x}) - 11'sd181;
    wire signed [10:0] dy = $signed({1'b0, y}) - 11'sd144;
    wire signed [21:0] d2 = dx * dx + dy * dy;
    wire bub_ring  = gset && ginv && (d2 <= 22'sd25) && (d2 > 22'sd9);
    wire bub_inner = gset && ginv && (d2 <= 22'sd9);

    //==========================================================================
    // level 1 : 2x2 K-map
    //==========================================================================
    wire in_grid   = inbox(x, y, 10'd432, 10'd112, 10'd528, 10'd208);
    wire ci1       = (x >= 10'd480);
    wire ri1       = (y >= 10'd160);
    wire [9:0] cx0 = ci1 ? 10'd480 : 10'd432;
    wire [9:0] cy0 = ri1 ? 10'd160 : 10'd112;
    wire [9:0] relx = x - cx0;
    wire [9:0] rely = y - cy0;
    wire cell_val  = val[{ri1, ci1}];
    wire grid_line = (relx == 10'd0) || (rely == 10'd0) ||
                     (x == 10'd527) || (y == 10'd207);

    //==========================================================================
    // level 2 : two 4:1 MUX (x 232~312) and one 2:1 MUX (x 392~440)
    //   upper MUX y 96~208, lower MUX y 224~336, final MUX y 136~296 (trapezoids)
    //==========================================================================
    wire [9:0] mt  = (x >= 10'd232) ? ((x - 10'd232) >> 1) : 10'd0;
    wire [9:0] mt3 = (x >= 10'd392) ? ((x - 10'd392) >> 1) : 10'd0;

    wire m1_in = (x >= 10'd232) && (x < 10'd312) && (y >= 10'd96  + mt) && (y < 10'd208 - mt);
    wire m2_in = (x >= 10'd232) && (x < 10'd312) && (y >= 10'd224 + mt) && (y < 10'd336 - mt);
    wire m3_in = (x >= 10'd392) && (x < 10'd440) && (y >= 10'd136 + mt3) && (y < 10'd296 - mt3);
    wire m1_edge = m1_in && ((y < 10'd98  + mt) || (y >= 10'd206 - mt) || (x < 10'd234) || (x >= 10'd310));
    wire m2_edge = m2_in && ((y < 10'd226 + mt) || (y >= 10'd334 - mt) || (x < 10'd234) || (x >= 10'd310));
    wire m3_edge = m3_in && ((y < 10'd138 + mt3) || (y >= 10'd294 - mt3) || (x < 10'd394) || (x >= 10'd438));

    wire sel0 = (sel == 2'd0), sel1 = (sel == 2'd1), sel2 = (sel == 2'd2), sel3 = (sel == 2'd3);

    // data wires: D0..D3 (upper), E0..E3 (lower)
    wire w_d0 = hseg(x, y, 10'd104, 10'd232, 10'd103);
    wire w_d1 = hseg(x, y, 10'd104, 10'd232, 10'd135);
    wire w_d2 = hseg(x, y, 10'd104, 10'd232, 10'd167);
    wire w_d3 = hseg(x, y, 10'd104, 10'd232, 10'd199);
    wire w_e0 = hseg(x, y, 10'd104, 10'd232, 10'd231);
    wire w_e1 = hseg(x, y, 10'd104, 10'd232, 10'd263);
    wire w_e2 = hseg(x, y, 10'd104, 10'd232, 10'd295);
    wire w_e3 = hseg(x, y, 10'd104, 10'd232, 10'd327);
    wire w_up  = hseg(x, y, 10'd312, 10'd392, 10'd152);   // upper MUX -> 2:1 MUX
    wire w_low = hseg(x, y, 10'd312, 10'd392, 10'd280);   // lower MUX -> 2:1 MUX
    wire w_out = hseg(x, y, 10'd440, 10'd488, 10'd215);   // 2:1 MUX output

    // select wires: A, B go to both 4:1 MUX (upper one from above, lower one from below), C to the 2:1 MUX
    wire w_a1 = vseg(x, y, 10'd256, 10'd96,  10'd120);
    wire w_b1 = vseg(x, y, 10'd288, 10'd96,  10'd132);
    wire w_a2 = vseg(x, y, 10'd256, 10'd316, 10'd352);
    wire w_b2 = vseg(x, y, 10'd288, 10'd300, 10'd352);
    wire w_c  = vseg(x, y, 10'd416, 10'd284, 10'd352);

    // the path through the chosen MUX is yellow
    wire hot_up  = (sel0 & w_d0) | (sel1 & w_d1) | (sel2 & w_d2) | (sel3 & w_d3) | w_up;
    wire hot_low = (sel0 & w_e0) | (sel1 & w_e1) | (sel2 & w_e2) | (sel3 & w_e3) | w_low;
    wire w_hot  = (csel ? hot_low : hot_up) | w_out;
    // single 8:1 MUX (Q4): body x 232~312, y 96~336, inputs on the same 8 data wires
    wire m8_in   = (x >= 10'd232) && (x < 10'd312) && (y >= 10'd96 + mt) && (y < 10'd336 - mt);
    wire m8_edge = m8_in && ((y < 10'd98 + mt) || (y >= 10'd334 - mt) || (x < 10'd234) || (x >= 10'd310));
    wire w8_out  = hseg(x, y, 10'd312, 10'd488, 10'd215);
    wire w8_a    = vseg(x, y, 10'd248, 10'd320, 10'd352);
    wire w8_b    = vseg(x, y, 10'd272, 10'd308, 10'd352);
    wire w8_c    = vseg(x, y, 10'd296, 10'd296, 10'd352);
    wire [7:0] wd = {w_e3, w_e2, w_e1, w_e0, w_d3, w_d2, w_d1, w_d0};
    wire [2:0] idx8 = {sel, csel};
    wire w8_hot  = wd[idx8] | w8_out;
    wire w8_any  = (|wd) | w8_out | w8_a | w8_b | w8_c;

    wire w_any  = w_d0 | w_d1 | w_d2 | w_d3 | w_e0 | w_e1 | w_e2 | w_e3 | w_up | w_low | w_out |
                  w_a1 | w_b1 | w_a2 | w_b2 | w_c;

    // screen border (green for correct, red for wrong)
    wire frame = (x < 10'd4) || (x >= 10'd636) || (y < 10'd4) || (y >= 10'd476);

    // decorative box for the title / end screen
    wire deco = boxedge(x, y, 10'd104, 10'd104, 10'd536, 10'd312, 10'd2);

    // divider line
    wire sep = (y == 10'd60 || y == 10'd376) && (x >= 10'd8) && (x < 10'd632);

    always @* begin
        rgb = C_BG;

        if (state == S_TITLE || state == S_END) begin
            if (deco) rgb = C_CYAN;
            else if (x >= 10'd106 && x < 10'd534 && y >= 10'd106 && y < 10'd310) rgb = C_PANEL;
        end else if (game_view) begin
            if (sep) rgb = C_GRAY;
            else rgb = C_PANEL;

            if (lv1) begin
                if (w1_a | w1_b | w1_f) rgb = C_WHITE;
                if (sym_on)             rgb = (state == S_CORRECT) ? C_GREEN : C_YELLOW;
                if (sym_box)            rgb = C_GRAY;
                if (bub_ring)           rgb = (state == S_CORRECT) ? C_GREEN : C_YELLOW;
                if (bub_inner)          rgb = C_PANEL;

                if (in_grid) begin
                    rgb = cell_val ? C_CELL1 : C_CELL0;
                    if (grid_line) rgb = C_GRAY;
                end
            end else begin
                if (mode8) begin
                    if (m8_in)   rgb = C_BOXBG;
                    if (m8_edge) rgb = C_WHITE;
                    if (w8_any)  rgb = C_WHITE;
                    if (w8_hot && rev2) rgb = C_YELLOW;
                end else begin
                    if (m1_in | m2_in | m3_in)       rgb = C_BOXBG;
                    if (m1_edge | m2_edge | m3_edge) rgb = C_WHITE;
                    if (w_any)                       rgb = C_WHITE;
                    if (w_hot && rev2)                rgb = C_YELLOW;
                end
            end
        end

        // border for the correct / wrong screen
        if (frame) begin
            if (state == S_CORRECT)    rgb = C_GREEN;
            else if (state == S_WRONG) rgb = C_RED;
        end
    end
endmodule
