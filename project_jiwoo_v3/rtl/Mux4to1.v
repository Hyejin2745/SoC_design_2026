`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// Mux4to1 : 4-to-1 multiplexer, 4-bit data (Lab2 Mux4to1.v, conditional expression)
//   {A,B} = 00 -> I0, 01 -> I1, 10 -> I2, 11 -> I3   (A is the high bit)
//------------------------------------------------------------------------------
module Mux4to1 (I0, I1, I2, I3, A, B, Z1);
input [3:0] I0, I1, I2, I3;
input A, B;
output [3:0] Z1;

assign Z1 = ({A, B} == 2'b00) ? I0 :
            ({A, B} == 2'b01) ? I1 :
            ({A, B} == 2'b10) ? I2 : I3;

endmodule
