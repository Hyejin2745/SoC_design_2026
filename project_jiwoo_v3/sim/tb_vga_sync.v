`timescale 1ns / 1ps
// vga_sync : measures the HS and VS period and width
//   horizontal 800 pixels (sync width 96), vertical 525 lines (sync width 2 lines), visible area 640x480 = 307200 pixels
module tb_vga_sync;
    reg clk = 0, rst = 1;
    always #5 clk = ~clk;

    wire        en25;
    wire [9:0]  x, y;
    wire        hs, vs, active;

    vga_sync dut (
        clk,                        // clk
        rst,                        // rst
        en25,                       // pix_en
        x,                          // x
        y,                          // y
        hs,                         // hs
        vs,                         // vs
        active                      // active
    );

    integer errors = 0;
    integer pix = 0, line = 0;
    integer hs_fall1 = -1, hs_fall2 = -1;      // pixel number where the HS falling edge occurred
    integer vs_fall1 = -1, vs_fall2 = -1;      // line number where the VS falling edge occurred
    integer hs_w = 0, hs_w_seen = -1;
    integer vs_w = 0, vs_w_seen = -1;
    integer act_pix = 0, act_frames = 0;
    reg hs_d = 1, vs_d = 1, counting = 0;

    initial begin
        repeat (3) @(posedge clk);
        #1 rst = 0;
    end

    always @(posedge clk) begin
        if (!rst && en25) begin
            pix = pix + 1;
            if (x == 10'd0) line = line + 1;

            // HS
            if (hs_d && !hs) begin
                if (hs_fall1 < 0) hs_fall1 = pix; else if (hs_fall2 < 0) hs_fall2 = pix;
                hs_w = 0;
            end
            if (!hs) hs_w = hs_w + 1;
            if (!hs_d && hs && hs_w_seen < 0) hs_w_seen = hs_w;

            // VS (width in lines)
            if (vs_d && !vs) begin
                if (vs_fall1 < 0) vs_fall1 = line; else if (vs_fall2 < 0) vs_fall2 = line;
                vs_w = 0;
            end
            if (!vs && x == 10'd0) vs_w = vs_w + 1;
            if (!vs_d && vs && vs_w_seen < 0) vs_w_seen = vs_w;

            hs_d = hs;
            vs_d = vs;

            // number of visible pixels (one frame)
            if (x == 10'd0 && y == 10'd0) begin
                if (counting) begin
                    if (act_pix !== 307200) begin
                        errors = errors + 1;
                        $display("FAIL: active pixels per frame = %0d", act_pix);
                    end
                    act_frames = act_frames + 1;
                end
                counting = 1;
                act_pix = 0;
            end
            if (counting && active) act_pix = act_pix + 1;
        end
    end

    initial begin
        wait (act_frames >= 2);
        if (hs_fall2 - hs_fall1 !== 800) begin errors = errors + 1; $display("FAIL: H period %0d", hs_fall2 - hs_fall1); end
        else $display("ok  : H period = 800 pixels");
        if (hs_w_seen !== 96) begin errors = errors + 1; $display("FAIL: HS width %0d", hs_w_seen); end
        else $display("ok  : HS low width = 96 pixels");
        if (vs_fall2 - vs_fall1 !== 525) begin errors = errors + 1; $display("FAIL: V period %0d", vs_fall2 - vs_fall1); end
        else $display("ok  : V period = 525 lines");
        if (vs_w_seen !== 2) begin errors = errors + 1; $display("FAIL: VS width %0d", vs_w_seen); end
        else $display("ok  : VS low width = 2 lines");
        $display("tb_vga_sync : %0d errors -> %s", errors, errors == 0 ? "PASS" : "FAIL");
        $finish;
    end

    initial begin
        #200_000_000;
        $display("tb_vga_sync : TIMEOUT -> FAIL");
        $finish;
    end
endmodule
