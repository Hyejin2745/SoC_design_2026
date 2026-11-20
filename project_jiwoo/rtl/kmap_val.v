`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// kmap_val : truth table of a circuit. val[i] = F when {A,B,C,D} = i.
//   Built from 16 copies of circuit_eval, so the K-map shown on screen and the
//   answer check both use exactly the same circuit model.
//------------------------------------------------------------------------------
module kmap_val (
    input  wire [2:0]  g1,
    input  wire [2:0]  g2,
    input  wire [2:0]  g3,
    input  wire        single,
    output wire [15:0] val
);
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : g_cell
            localparam [3:0] V = i;
            circuit_eval u_c (V, g1, g2, g3, single, val[i]);
        end
    endgenerate
endmodule
