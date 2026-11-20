`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// gate_unit : 2-input gate whose type is chosen by a 3-bit code
//   code[2]   : invert the output
//   code[1:0] : base gate (00 AND, 01 OR, 10 XOR, 11 unused)
//   000 AND  001 OR  010 XOR  100 NAND  101 NOR  110 XNOR
//------------------------------------------------------------------------------
module gate_unit (
    input  wire       a,
    input  wire       b,
    input  wire [2:0] code,
    output wire       y
);
    reg base;
    always @* begin
        case (code[1:0])
            2'b00:   base = a & b;
            2'b01:   base = a | b;
            2'b10:   base = a ^ b;
            default: base = 1'b0;
        endcase
    end
    assign y = base ^ code[2];
endmodule
