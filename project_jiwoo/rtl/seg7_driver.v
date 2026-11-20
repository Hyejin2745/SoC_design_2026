`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// seg7_driver : 8-digit multiplexed 7-segment display (Nexys4 DDR: segments and digit selects are all active-low)
//   digits[4*i +: 4] = value shown on digit AN[i] (0~9, A~F)
//   dp_mask[i]=1 turns on the decimal point of that digit, blank[i]=1 turns that digit off
//   seg_n = {CG,CF,CE,CD,CC,CB,CA}
//------------------------------------------------------------------------------
module seg7_driver (
    input  wire        clk,
    input  wire        rst,
    input  wire        scan_tick,
    input  wire [31:0] digits,
    input  wire [7:0]  dp_mask,
    input  wire [7:0]  blank,
    output wire [7:0]  an,
    output wire [6:0]  seg_n,
    output wire        dp_n
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
            4'h0: pat = 7'h3F;
            4'h1: pat = 7'h06;
            4'h2: pat = 7'h5B;
            4'h3: pat = 7'h4F;
            4'h4: pat = 7'h66;
            4'h5: pat = 7'h6D;
            4'h6: pat = 7'h7D;
            4'h7: pat = 7'h07;
            4'h8: pat = 7'h7F;
            4'h9: pat = 7'h6F;
            4'hA: pat = 7'h77;
            4'hB: pat = 7'h7C;
            4'hC: pat = 7'h39;
            4'hD: pat = 7'h5E;
            4'hE: pat = 7'h79;
            default: pat = 7'h71;
        endcase
    end

    wire show = ~blank[sel];
    assign an    = show ? ~(8'd1 << sel) : 8'hFF;
    assign seg_n = ~pat;
    assign dp_n  = ~dp_mask[sel];
endmodule
