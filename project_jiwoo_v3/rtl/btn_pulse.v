`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// btn_pulse : button debounce + one-pulse (din must already be synchronized, see sync_ff)
//   Looks at the input on every tick (1kHz); if a value different from the current stable
//   state is held for STABLE consecutive samples (10 -> about 10ms), the stable state changes.
//   pulse is 1 for one clock when the stable state changes from 0 to 1 (button pressed).
//------------------------------------------------------------------------------
module btn_pulse #(
    parameter STABLE = 10
) (
    input  wire clk,
    input  wire rst,
    input  wire tick,
    input  wire din,
    output reg  pulse
);
    reg       stable;
    reg [3:0] cnt;

    always @(posedge clk) begin
        pulse <= 1'b0;
        if (rst) begin
            stable <= 1'b0;
            cnt    <= 4'd0;
        end else if (tick) begin
            if (din == stable) begin
                cnt <= 4'd0;
            end else if (cnt == STABLE - 1) begin
                stable <= din;
                pulse  <= din;
                cnt    <= 4'd0;
            end else begin
                cnt <= cnt + 4'd1;
            end
        end
    end
endmodule
