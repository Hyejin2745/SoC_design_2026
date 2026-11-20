`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// Button : synchronizer + single pulser (based on the Lab10 Button.v)
//   btn1 -> btn2 -> btn3 is the 3-FF chain of the lecture code.
//   pls = btn2 & !btn3 is high for one clock when the button is pressed (0 -> 1).
//   Added for the real board: a mechanical button bounces for a few ms, so after every
//   edge (press or release) further pulses are blocked for LOCK clocks (default 10ms).
//   rst is active low, same as the lecture code (CPU_RESETN).
//------------------------------------------------------------------------------
module Button #(
    parameter LOCK = 1_000_000          // 100MHz * 10ms
) (
    input clk, rst, btn,
    output wire pls
);

reg btn1 = 1'b0;
reg btn2 = 1'b0;
reg btn3 = 1'b0;
reg [19:0] lock = 20'd0;

always @(posedge clk) begin
    if(!rst) begin
        btn1 <= 1'b0;
        btn2 <= 1'b0;
        btn3 <= 1'b0;
        lock <= 20'd0;
    end
    else begin
        btn1 <= btn;
        btn2 <= btn1;
        btn3 <= btn2;
        if (btn2 != btn3) lock <= LOCK;
        else if (lock != 20'd0) lock <= lock - 20'd1;
    end
end

assign pls = btn2 & !btn3 & (lock == 20'd0);

endmodule
