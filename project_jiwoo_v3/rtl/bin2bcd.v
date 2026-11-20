`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// bin2bcd : Double-Dabble (shift-and-add-3) 10-bit binary -> 3-digit BCD (0~999)
//------------------------------------------------------------------------------
module bin2bcd (
    input  wire [9:0]  bin,
    output wire [11:0] bcd
);
    reg [21:0] sh;
    integer i;

    always @* begin
        sh = {12'd0, bin};
        for (i = 0; i < 10; i = i + 1) begin
            if (sh[13:10] >= 4'd5) sh[13:10] = sh[13:10] + 4'd3;
            if (sh[17:14] >= 4'd5) sh[17:14] = sh[17:14] + 4'd3;
            if (sh[21:18] >= 4'd5) sh[21:18] = sh[21:18] + 4'd3;
            sh = sh << 1;
        end
    end

    assign bcd = sh[21:10];
endmodule
