`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// debounce : button bounce removal
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
    reg       s0, s1;
    reg [7:0] cnt;

    always @(posedge clk) begin
        if (rst) begin
            s0   <= 1'b0;
            s1   <= 1'b0;
            cnt  <= 8'd0;
            dout <= 1'b0;
        end else begin
            s0 <= din;
            s1 <= s0;
            if (tick) begin
                if (s1 == dout) begin
                    cnt <= 8'd0;
                end else if (cnt == STABLE - 1) begin
                    dout <= s1;
                    cnt  <= 8'd0;
                end else begin
                    cnt <= cnt + 8'd1;
                end
            end
        end
    end
endmodule
