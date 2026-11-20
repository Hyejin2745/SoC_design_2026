`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// bin2bcd : Double-Dabble (shift-and-add-3) binary -> 3-digit BCD (0~999)
//------------------------------------------------------------------------------
module bin2bcd #(
    parameter W = 10
) (
    input  wire [W-1:0] bin,
    output wire [11:0]  bcd
);
    reg [W+11:0] sh;
    integer i;

    always @* begin
        sh = {(W + 12){1'b0}};
        sh[W-1:0] = bin;
        for (i = 0; i < W; i = i + 1) begin
            if (sh[W+3  : W]   >= 4'd5) sh[W+3  : W]   = sh[W+3  : W]   + 4'd3;
            if (sh[W+7  : W+4] >= 4'd5) sh[W+7  : W+4] = sh[W+7  : W+4] + 4'd3;
            if (sh[W+11 : W+8] >= 4'd5) sh[W+11 : W+8] = sh[W+11 : W+8] + 4'd3;
            sh = sh << 1;
        end
    end

    assign bcd = sh[W+11 : W];
endmodule
