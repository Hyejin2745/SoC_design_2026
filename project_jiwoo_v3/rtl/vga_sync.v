`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// vga_sync : 640x480 @ 60Hz sync signals and the current pixel coordinate
//   Advances one pixel per pix_en (25MHz enable, 1 every 4 clocks, also used by renderer).
//   Only the single 100MHz clock is used.
//   Horizontal: visible 640 + front 16 + sync 96 + back 48 = 800
//   Vertical  : visible 480 + front 10 + sync 2  + back 33 = 525
//   HS and VS are active-low
//------------------------------------------------------------------------------
module vga_sync (
    input  wire       clk,
    input  wire       rst,
    output wire       pix_en,
    output reg  [9:0] x,
    output reg  [9:0] y,
    output wire       hs,
    output wire       vs,
    output wire       active
);
    reg [1:0] div;
    assign pix_en = (div == 2'd3);

    always @(posedge clk) begin
        div <= !rst ? 2'd0 : div + 2'd1;
        if (!rst) begin
            x <= 10'd0;
            y <= 10'd0;
        end else if (pix_en) begin
            if (x == 10'd799) begin
                x <= 10'd0;
                if (y == 10'd524) y <= 10'd0;
                else              y <= y + 10'd1;
            end else begin
                x <= x + 10'd1;
            end
        end
    end

    assign hs     = ~(x >= 10'd656 && x < 10'd752);
    assign vs     = ~(y >= 10'd490 && y < 10'd492);
    assign active = (x < 10'd640) && (y < 10'd480);
endmodule
