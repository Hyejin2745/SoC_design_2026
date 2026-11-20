`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// clk_en : only the single 100MHz clock is used; slow behaviour is made with enable pulses.
//   en25 : 1 every 4 clocks -> VGA pixel enable (25MHz)
//   en1m : 1 every DIV_1M clocks (default 100 -> 1MHz) -> sound pitch
//   en1k : 1 every DIV_1K en1m pulses (default 1000 -> 1kHz)
//          -> button debounce sampling, 7-seg scan, sound note length
// In simulation DIV_1M and DIV_1K are reduced so it runs fast.
//------------------------------------------------------------------------------
module clk_en #(
    parameter DIV_1M = 100,
    parameter DIV_1K = 1000
) (
    input  wire clk,
    input  wire rst,
    output wire en25,
    output wire en1m,
    output wire en1k
);
    reg [1:0]  c25;
    reg [15:0] c1m;
    reg [15:0] c1k;

    assign en25 = (c25 == 2'd3);
    assign en1m = (c1m == DIV_1M - 1);
    assign en1k = en1m && (c1k == DIV_1K - 1);

    always @(posedge clk) begin
        if (rst) begin
            c25 <= 2'd0;
            c1m <= 16'd0;
            c1k <= 16'd0;
        end else begin
            c25 <= c25 + 2'd1;
            if (en1m) begin
                c1m <= 16'd0;
                if (c1k == DIV_1K - 1) c1k <= 16'd0;
                else                   c1k <= c1k + 16'd1;
            end else begin
                c1m <= c1m + 16'd1;
            end
        end
    end
endmodule
