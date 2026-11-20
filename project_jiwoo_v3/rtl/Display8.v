`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// Display8 : 8-digit 7-segment display (the Lab10 Display4.v extended from 2 to 8 digits)
//   Same structure as the lecture code:
//     - a counter divides the clock (every 10000 clocks = 100us the next digit is selected)
//     - digit is the one-cold digit select (AN), it rotates 11111110 -> 11111101 -> ...
//     - dec = the 4-bit value of the selected digit, seg = active-low pattern (seg = {CA..CG})
//   digits[4*i +: 4] = value shown on digit AN[i] (0~9). Any other value (use 4'hF) turns the digit off.
//   The divided clock is used as an enable (tick) instead of a second clock.
//   rst is active low.
//------------------------------------------------------------------------------
module Display8(
    input clk, rst,
    input [31:0] digits,
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
    else if(tick) digit <= {digit[6:0], digit[7]};
end

reg [3:0] dec;

always @(*) begin
    case (digit)
        8'b11111110: dec = digits[3:0];
        8'b11111101: dec = digits[7:4];
        8'b11111011: dec = digits[11:8];
        8'b11110111: dec = digits[15:12];
        8'b11101111: dec = digits[19:16];
        8'b11011111: dec = digits[23:20];
        8'b10111111: dec = digits[27:24];
        8'b01111111: dec = digits[31:28];
        default: dec = 4'hF;
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
