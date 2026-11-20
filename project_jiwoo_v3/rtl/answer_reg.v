`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// answer_reg : level 1 answer (the gate the player tries)
//   BTNU = AND   BTNL = OR   BTNR = XOR   : choose the base gate (latched)
//   sw_not (switch) : inverts the gate (OR + NOT = NOR, AND + NOT = NAND, XOR + NOT = XNOR)
//   The switch is read live, so the gate symbol on the screen follows it immediately.
//   a_g1 uses the gate_unit code ({invert, base}); 3'b111 = no gate chosen yet.
//------------------------------------------------------------------------------
module answer_reg (
    input  wire       clk,
    input  wire       rst,
    input  wire       clr,
    input  wire       edit_en,
    input  wire       bu,        // AND
    input  wire       bl,        // OR
    input  wire       br,        // XOR
    input  wire       sw_not,    // NOT
    output wire [2:0] a_g1,
    output wire       ans_full
);
    reg [1:0] base;
    reg       set;

    always @(posedge clk) begin
        if (!rst || clr) begin
            base <= 2'd0;
            set  <= 1'b0;
        end else if (edit_en && (bu || bl || br)) begin
            base <= bu ? 2'd0 : bl ? 2'd1 : 2'd2;
            set  <= 1'b1;
        end
    end

    assign a_g1     = set ? {sw_not, base} : 3'b111;
    assign ans_full = set;
endmodule
