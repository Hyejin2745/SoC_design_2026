`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// circuit_eval : one circuit of the form F = G3( G1(A,B), G2(C,D) )
//   The hidden circuit and the player's answer circuit use the same module.
//   single=1 gives a one-gate circuit (F = n1)
//   in_vec = {A,B,C,D}
//------------------------------------------------------------------------------
module circuit_eval (
    input  wire [3:0] in_vec,
    input  wire [2:0] g1,
    input  wire [2:0] g2,
    input  wire [2:0] g3,
    input  wire       single,
    output wire       f
);
    wire n1, n2, out3;
    gate_unit u_g1 (in_vec[3], in_vec[2], g1, n1);
    gate_unit u_g2 (in_vec[1], in_vec[0], g2, n2);
    gate_unit u_g3 (n1, n2, g3, out3);

    assign f = single ? n1 : out3;
endmodule
