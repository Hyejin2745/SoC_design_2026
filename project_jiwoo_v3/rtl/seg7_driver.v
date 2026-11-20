`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// seg7_driver : 8-digit multiplexed 7-segment display (Nexys4 DDR: segments and digit selects are active-low)
//   digits[4*i +: 4] = decimal value (0~9) shown on digit AN[i]
//   blank[i]=1 turns that digit off
//   seg_n = {CG,CF,CE,CD,CC,CB,CA}
//------------------------------------------------------------------------------
module seg7_driver (
    input  wire        clk,
    input  wire        rst,
    input  wire        scan_tick,
    input  wire [31:0] digits,
    input  wire [7:0]  blank,
    output wire [7:0]  an,
    output wire [6:0]  seg_n
);
    reg [2:0] sel;
    always @(posedge clk) begin
        if (rst)            sel <= 3'd0;
        else if (scan_tick) sel <= sel + 3'd1;
    end

    wire [3:0] d = digits[sel*4 +: 4];

    reg [6:0] pat;   // active-high, bit0 = a ... bit6 = g
    always @* begin
        case (d)
            4'd0:    pat = 7'h3F;
            4'd1:    pat = 7'h06;
            4'd2:    pat = 7'h5B;
            4'd3:    pat = 7'h4F;
            4'd4:    pat = 7'h66;
            4'd5:    pat = 7'h6D;
            4'd6:    pat = 7'h7D;
            4'd7:    pat = 7'h07;
            4'd8:    pat = 7'h7F;
            default: pat = 7'h6F;
        endcase
    end

    assign an    = blank[sel] ? 8'hFF : ~(8'd1 << sel);
    assign seg_n = ~pat;
endmodule
