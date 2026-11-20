`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// Mux : 2-to-1 multiplexer, 4-bit data (Lab2 Mux.v, conditional expression)
//   A = 0 -> Z = X,  A = 1 -> Z = Y
//------------------------------------------------------------------------------
module Mux(X, Y, A, Z);
input [3:0] X, Y;
input A;
output [3:0] Z;

assign Z = (A) ? Y : X;

endmodule
