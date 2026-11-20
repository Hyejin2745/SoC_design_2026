`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// Mux8to1 : 8-to-1 multiplexer built from two 4-to-1 and one 2-to-1 multiplexer
//   (the Lab2 exercise). Input number = {A,B,C}, A is the high bit.
//   A,B select inside both 4-to-1 MUX, C selects between them.
//------------------------------------------------------------------------------
module Mux8to1 (X0, X1, X2, X3, X4, X5, X6, X7, A, B, C, Z1);
input [3:0] X0, X1, X2, X3, X4, X5, X6, X7;
input A, B, C;
output [3:0] Z1;

wire [3:0] W1, W2;

Mux4to1 U1 (X0, X2, X4, X6, A, B, W1);   // C = 0
Mux4to1 U2 (X1, X3, X5, X7, A, B, W2);   // C = 1
Mux     U3 (W1, W2, C, Z1);

endmodule
