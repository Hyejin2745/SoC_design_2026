`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// renderer : combines 3 layers (background / shape / text) into a pixel colour (no frame buffer)
//   Priority: text > shape > background. Outside the visible area RGB = 0.
//
//   Pipeline (every stage advances one step per pix_en = 25MHz enable)
//     stage1 : store the text_gen / shape_gen result (character code, shape colour, position inside the cell)
//     stage2 : read the 8 pixels of that row from font_rom and store them (the read takes one stage)
//     stage3 : choose the colour from the text pixel flag and store it in the output register
//   HS, VS and active also pass through the same 3 stages, so the text does not shift.
//------------------------------------------------------------------------------
module renderer (
    input  wire        clk,
    input  wire        rst,
    input  wire        pix_en,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire        hs_in,
    input  wire        vs_in,
    input  wire        active_in,
    // game state
    input  wire [3:0]  state,
    input  wire [1:0]  level,
    input  wire [2:0]  qnum,
    input  wire [1:0]  lives,
    input  wire        lives_zero,
    input  wire [3:0]  s2, s1, s0,
    input  wire [3:0]  b2, b1, b0,
    input  wire [3:0]  p2, p1, p0,
    input  wire [2:0]  a_g1,         // player's gate (level 1), 111 = not set
    input  wire [2:0]  h_g1,         // hidden gate (level 1)
    input  wire        reveal,
    input  wire [15:0] val,          // K-map of the hidden gate
    input  wire [3:0]  d0, d1, d2, d3,   // upper 4:1 MUX data (level 2)
    input  wire [3:0]  e0, e1, e2, e3,   // lower 4:1 MUX data (level 2)
    input  wire [3:0]  tgt,          // target number
    input  wire [1:0]  sel,          // A, B (select of both 4:1 MUX)
    input  wire        csel,         // C (select of the 2:1 MUX, low bit of the 8:1 MUX)
    input  wire        mode8,        // 1 = single 8:1 MUX, 0 = 4:1 + 4:1 + 2:1
    input  wire [3:0]  mux_out,      // MUX output
    // VGA output
    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b,
    output reg         vga_hs,
    output reg         vga_vs
);
    // ---- build the layers (combinational) ------------------------------------
    wire [7:0]  ch;
    wire [2:0]  attr;
    wire [11:0] shp;

    wire [2:0] gcode = reveal ? h_g1 : a_g1;

    text_gen u_text (
        x[9:3], y[8:4], state, level, qnum, lives, lives_zero,
        s2, s1, s0, b2, b1, b0, p2, p1, p0,
        gcode, val, d0, d1, d2, d3, e0, e1, e2, e3, tgt, sel, csel, mode8, mux_out,
        ch, attr
    );

    shape_gen u_shape (
        x, y, state, level, gcode, val, sel, csel, mode8, shp
    );

    // ---- stage 1 -------------------------------------------------------------
    reg [7:0]  ch1;
    reg [2:0]  at1;
    reg [11:0] sh1;
    reg [2:0]  xb1;
    reg [3:0]  yb1;
    reg        hs1, vs1, ac1;

    always @(posedge clk) begin
        if (rst) begin
            ch1 <= 8'h20; at1 <= 3'd0; sh1 <= 12'd0; xb1 <= 3'd0; yb1 <= 4'd0;
            hs1 <= 1'b1;  vs1 <= 1'b1; ac1 <= 1'b0;
        end else if (pix_en) begin
            ch1 <= ch;
            at1 <= attr;
            sh1 <= shp;
            xb1 <= x[2:0];
            yb1 <= y[3:0];
            hs1 <= hs_in;
            vs1 <= vs_in;
            ac1 <= active_in;
        end
    end

    // ---- stage 2 : font ROM --------------------------------------------------
    wire [7:0] fbits;
    font_rom u_font (ch1, yb1, fbits);

    reg [7:0]  fb2;
    reg [2:0]  at2;
    reg [11:0] sh2;
    reg [2:0]  xb2;
    reg        hs2, vs2, ac2;

    always @(posedge clk) begin
        if (rst) begin
            fb2 <= 8'd0; at2 <= 3'd0; sh2 <= 12'd0; xb2 <= 3'd0;
            hs2 <= 1'b1; vs2 <= 1'b1; ac2 <= 1'b0;
        end else if (pix_en) begin
            fb2 <= fbits;
            at2 <= at1;
            sh2 <= sh1;
            xb2 <= xb1;
            hs2 <= hs1;
            vs2 <= vs1;
            ac2 <= ac1;
        end
    end

    // ---- stage 3 : colour select ---------------------------------------------
    wire txt_on = fb2[3'd7 - xb2];

    reg [11:0] txt_rgb;
    always @* begin
        case (at2)
            3'd0:    txt_rgb = 12'hFFF;   // white
            3'd1:    txt_rgb = 12'hFE0;   // yellow
            3'd2:    txt_rgb = 12'h4F4;   // green
            3'd3:    txt_rgb = 12'hF44;   // red
            3'd4:    txt_rgb = 12'h4EF;   // light blue
            default: txt_rgb = 12'h99A;   // gray
        endcase
    end

    wire [11:0] pix = txt_on ? txt_rgb : sh2;

    always @(posedge clk) begin
        if (rst) begin
            vga_r <= 4'd0; vga_g <= 4'd0; vga_b <= 4'd0;
            vga_hs <= 1'b1; vga_vs <= 1'b1;
        end else if (pix_en) begin
            vga_hs <= hs2;
            vga_vs <= vs2;
            if (ac2) begin
                vga_r <= pix[11:8];
                vga_g <= pix[7:4];
                vga_b <= pix[3:0];
            end else begin
                vga_r <= 4'd0;
                vga_g <= 4'd0;
                vga_b <= 4'd0;
            end
        end
    end
endmodule
