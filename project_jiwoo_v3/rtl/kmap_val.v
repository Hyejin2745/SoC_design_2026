`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// kmap_val : 2x2 truth table of one gate. val[{A,B}] = gate(A,B).
//   Used for the K-map shown on screen.
//------------------------------------------------------------------------------
module kmap_val (
    input  wire [2:0] g,
    output wire [3:0] val
);
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : g_cell
            localparam [1:0] V = i;
            gate_unit u_g (V[1], V[0], g, val[i]);
        end
    endgenerate
endmodule
