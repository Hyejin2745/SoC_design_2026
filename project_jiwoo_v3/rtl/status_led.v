`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// status_led : RGB LED (LD16) state display, blue = answering, green = correct / clear, red = wrong
//   The RGB LED is very bright, so it is PWM-driven at 1/16 brightness.
//   state numbers are the same as in control_fsm.
//------------------------------------------------------------------------------
module status_led (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] state,
    input  wire       lives_zero,
    output wire       r,
    output wire       g,
    output wire       b
);
    localparam S_ANSWER = 4'd5, S_CORRECT = 4'd7, S_WRONG = 4'd8, S_END = 4'd9;

    reg [3:0] dim;
    always @(posedge clk) begin
        if (rst) dim <= 4'd0;
        else     dim <= dim + 4'd1;
    end
    wire on = (dim == 4'd0);

    wire is_blue  = (state == S_ANSWER);
    wire is_green = (state == S_CORRECT) || (state == S_END && !lives_zero);
    wire is_red   = (state == S_WRONG)   || (state == S_END &&  lives_zero);

    assign b = on & is_blue;
    assign g = on & is_green;
    assign r = on & is_red;
endmodule
