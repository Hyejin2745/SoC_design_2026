`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// debounce : button bounce removal (din must already be synchronized, see sync_ff)
//   Looks at the input on every tick (1kHz); if a value different from the current output
//   is held for STABLE consecutive samples, the output changes. (STABLE=10 -> about 10ms)
//------------------------------------------------------------------------------
module debounce #(
    parameter STABLE = 10
) (
    input  wire clk,
    input  wire rst,
    input  wire tick,
    input  wire din,
    output reg  dout
);
    reg [3:0] cnt;

    always @(posedge clk) begin
        if (rst) begin
            cnt  <= 4'd0;
            dout <= 1'b0;
        end else if (tick) begin
            if (din == dout) begin
                cnt <= 4'd0;
            end else if (cnt == STABLE - 1) begin
                dout <= din;
                cnt  <= 4'd0;
            end else begin
                cnt <= cnt + 4'd1;
            end
        end
    end
endmodule
