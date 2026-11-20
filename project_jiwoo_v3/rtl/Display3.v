`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// Display3 : 3-digit 7-segment display (the Lab10 Display4.v with 3 digits: AN2, AN1, AN0)
//   Same structure as the lecture code:
//     - a counter divides the clock (every 10000 clocks = 100us the next digit is selected)
//     - digit is the one-cold digit select (AN), it rotates 11111110 -> 11111101 -> 11111011 -> ...
//       (AN7 ~ AN3 stay off)
//     - dec = the 4-bit value of the selected digit, seg = active-low pattern (seg = {CA..CG})
//   bcd[3:0] = digit AN0, bcd[7:4] = AN1, bcd[11:8] = AN2   (BCD, 0~9)
//   The divided clock is used as an enable (tick) instead of a second clock.
//   rst is active low.
//------------------------------------------------------------------------------
module Display3(
    input clk, rst,
    input [11:0] bcd,
    output reg [6:0] seg,
    output reg [7:0] digit
);

reg [13:0] count;
wire tick = (count == 14'd9999);

always @(posedge clk) begin
    if(!rst) count <= 14'b0;
    else if(tick) count <= 14'b0;
    else count <= count + 1;
end

always @(posedge clk) begin
    if(!rst) digit <= 8'b11111110;
    else if(tick)
        case(digit)
            8'b11111110: digit <= 8'b11111101;
            8'b11111101: digit <= 8'b11111011;
            default: digit <= 8'b11111110;
        endcase
end

reg [3:0] dec;

always @(*) begin
    case (digit)
        8'b11111110: dec = bcd[3:0];
        8'b11111101: dec = bcd[7:4];
        8'b11111011: dec = bcd[11:8];
        default: dec = 4'b0000;
    endcase
end

always @(*) begin
    case (dec)
        4'd0: seg = 7'b0000001;
        4'd1: seg = 7'b1001111;
        4'd2: seg = 7'b0010010;
        4'd3: seg = 7'b0000110;
        4'd4: seg = 7'b1001100;
        4'd5: seg = 7'b0100100;
        4'd6: seg = 7'b0100000;
        4'd7: seg = 7'b0001111;
        4'd8: seg = 7'b0000000;
        4'd9: seg = 7'b0000100;
        default: seg = 7'b1111111;
    endcase
end

endmodule
