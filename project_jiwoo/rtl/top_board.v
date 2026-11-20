`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// top_board : board-level top (Nexys4 DDR)
//   Switches : x[0] = SW0 = NOT (level 1)
//              x[3] = SW3 = A, x[2] = SW2 = B (select of both 4:1 MUX), x[1] = SW1 = C (2:1 MUX select)
//              sw4  = SW4 = submit / next (level 2)
//   Buttons  : BTNC = submit / next screen
//              BTNU = AND, BTNL = OR, BTNR = XOR (level 1 gate selection)
//   LEDs     : led_x[2:0] = lives, led_x[3] = ready to submit,
//              led_y[2:0] = state RGB LED (B,G,R), led_y[3] unused
//   7-seg    : seg[6:0] = {CA..CG}, digit[7:0] = AN[7:0]
//   rst      : CPU_RESETN pin (active low: pressed = 0)
//------------------------------------------------------------------------------
module top_board (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] x,
    input  wire       sw4,
    input  wire       BTNC,
    input  wire       BTNU,
    input  wire       BTNL,
    input  wire       BTNR,
    output wire [3:0] led_x,
    output wire [3:0] led_y,
    output wire [6:0] seg,
    output wire [7:0] digit,
    output wire [3:0] VGA_R,
    output wire [3:0] VGA_G,
    output wire [3:0] VGA_B,
    output wire       VGA_HS,
    output wire       VGA_VS
);
    wire [15:0] led;
    wire        led_r, led_g, led_b;
    wire        ca, cb, cc, cd, ce, cf, cg;

    top_bbd u_bbd (
        .CLK100MHZ  (clk),
        .CPU_RESETN (rst),
        .SW         ({sw4, x}),
        .BTNC(BTNC), .BTNU(BTNU), .BTNL(BTNL), .BTNR(BTNR),
        .LED        (led),
        .LED16_R    (led_r),
        .LED16_G    (led_g),
        .LED16_B    (led_b),
        .CA(ca), .CB(cb), .CC(cc), .CD(cd), .CE(ce), .CF(cf), .CG(cg),
        .DP         (),
        .AN         (digit),
        .VGA_R      (VGA_R), .VGA_G (VGA_G), .VGA_B (VGA_B),
        .VGA_HS     (VGA_HS), .VGA_VS (VGA_VS),
        .AUD_PWM    (), .AUD_SD ()
    );

    assign seg   = {ca, cb, cc, cd, ce, cf, cg};
    assign led_x = {led[3], led[2:0]};
    assign led_y = {1'b0, led_b, led_g, led_r};
endmodule
