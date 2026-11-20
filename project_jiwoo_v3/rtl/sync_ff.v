`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// sync_ff : synchronizes external inputs (switches, reset) to the clock with 2 flip-flops
//------------------------------------------------------------------------------
module sync_ff #(
    parameter W = 1
) (
    input  wire         clk,
    input  wire [W-1:0] d,
    output reg  [W-1:0] q
);
    reg [W-1:0] m;
    always @(posedge clk) begin
        m <= d;
        q <= m;
    end
endmodule
