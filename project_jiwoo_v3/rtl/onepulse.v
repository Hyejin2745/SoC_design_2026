`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// onepulse : outputs a 1-clock pulse when the input changes from 0 to 1
//------------------------------------------------------------------------------
module onepulse (
    input  wire clk,
    input  wire rst,
    input  wire din,
    output reg  pulse
);
    reg prev;
    always @(posedge clk) begin
        if (rst) begin
            prev  <= 1'b0;
            pulse <= 1'b0;
        end else begin
            prev  <= din;
            pulse <= din & ~prev;
        end
    end
endmodule
