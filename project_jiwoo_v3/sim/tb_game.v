`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// tb_game : plays one whole game on top_board (fast timing parameters)
//   Level 1 : BTNU = AND, BTNL = OR, BTNR = XOR, SW0 = NOT, BTNC = submit / next
//   Level 2 : SW3 = A, SW2 = B (both 4:1 MUX), SW1 = C (2:1 MUX), BTNC = submit / next
//   Scenario:
//     Q1 (AND)  : empty submit ignored, OR -> WRONG, retry AND -> CORRECT (70 pts)
//     Q2 (NOR)  : OR + SW0 -> CORRECT (100)
//     Q3 (XOR)  : XOR -> CORRECT (100)
//     Q4 (8:1 MUX, D=3,8,5,1,7,2,9,4 target 9)       : ABC=000 -> WRONG, retry ABC=110 -> CORRECT (70)
//     Q5 (4:1 x2 + 2:1, D=6,2,8,5 E=1,4,7,3 target 4) : ABC=011 -> CORRECT (100)
//   Expected: END state, 1 life left, score 440
//------------------------------------------------------------------------------
module tb_game;
    reg clk = 0, rstn = 0;
    reg bc = 0, bu = 0, bl = 0, br = 0;
    reg [3:0] sw = 4'd0;                 // {SW3, SW2, SW1, SW0}
    wire [3:0]  led_x, led_y;
    wire [6:0]  seg;
    wire [7:0]  digit;
    wire [3:0]  vr, vg, vb;
    wire hs, vs;

    top_board #(.DB_LOCK(3)) dut (
        .clk(clk), .rst(rstn), .x(sw),
        .BTNC(bc), .BTNU(bu), .BTNL(bl), .BTNR(br),
        .led_x(led_x), .led_y(led_y), .seg(seg), .digit(digit),
        .VGA_R(vr), .VGA_G(vg), .VGA_B(vb), .VGA_HS(hs), .VGA_VS(vs)
    );

    always #5 clk = ~clk;

    integer errors = 0;

    task press_c; begin bc = 1; repeat (150) @(posedge clk); bc = 0; repeat (150) @(posedge clk); end endtask
    task press_u; begin bu = 1; repeat (150) @(posedge clk); bu = 0; repeat (150) @(posedge clk); end endtask
    task press_l; begin bl = 1; repeat (150) @(posedge clk); bl = 0; repeat (150) @(posedge clk); end endtask
    task press_r; begin br = 1; repeat (150) @(posedge clk); br = 0; repeat (150) @(posedge clk); end endtask
    task set_abc; input [2:0] v; begin sw[3] = v[2]; sw[2] = v[1]; sw[1] = v[0]; repeat (50) @(posedge clk); end endtask

    task expect_state;
        input [3:0] st;
        input [255:0] what;
        begin
            if (dut.state !== st) begin
                errors = errors + 1;
                $display("FAIL %0s : state=%0d expected %0d (q=%0d)", what, dut.state, st, dut.qnum);
            end else
                $display("ok   %0s : state=%0d q=%0d score=%0d lives=%0d", what, dut.state, dut.qnum, dut.score, dut.lives);
        end
    endtask

    localparam S_TITLE = 0, S_ANSWER = 2, S_CORRECT = 3, S_WRONG = 4, S_END = 5;

    initial begin
        repeat (20) @(posedge clk);
        rstn = 1;
        repeat (50) @(posedge clk);
        expect_state(S_TITLE, "title");

        press_c;                                   // start
        expect_state(S_ANSWER, "Q1 answer");

        press_c;                                   // no gate chosen -> ignored
        expect_state(S_ANSWER, "Q1 empty submit ignored");
        press_l;                                   // OR (wrong, answer is AND)
        press_c;
        expect_state(S_WRONG, "Q1 wrong");
        press_c;                                   // try again
        expect_state(S_ANSWER, "Q1 retry");
        press_u;                                   // AND
        press_c;
        expect_state(S_CORRECT, "Q1 correct");
        press_c;

        expect_state(S_ANSWER, "Q2 answer");
        sw[0] = 1;                                 // NOT
        press_l;                                   // OR + NOT = NOR
        press_c;
        expect_state(S_CORRECT, "Q2 correct");
        sw[0] = 0;
        press_c;

        expect_state(S_ANSWER, "Q3 answer");
        press_r;                                   // XOR
        press_c;
        expect_state(S_CORRECT, "Q3 correct");
        press_c;

        expect_state(S_ANSWER, "Q4 answer");
        if (dut.level !== 2'd2) begin errors = errors + 1; $display("FAIL Q4 level=%0d", dut.level); end
        set_abc(3'b000);                           // D0 = 3, not the target 9
        press_c;
        expect_state(S_WRONG, "Q4 wrong");
        press_c;                                  // retry
        expect_state(S_ANSWER, "Q4 retry");
        set_abc(3'b110);                           // A=1 B=1 C=0 -> D6 = 9
        if (dut.mux_out !== 4'd9) begin errors = errors + 1; $display("FAIL mux_out=%0d expected 9", dut.mux_out); end
        expect_state(S_ANSWER, "Q4 not submitted yet");
        press_c;
        expect_state(S_CORRECT, "Q4 correct");
        press_c;                                  // next question

        expect_state(S_ANSWER, "Q5 answer");
        set_abc(3'b011);                           // A=0 B=1 C=1 -> E1 = 4
        press_c;
        expect_state(S_CORRECT, "Q5 correct");
        press_c;                                  // last question -> end

        expect_state(S_END, "end");
        if (dut.score !== 10'd440) begin errors = errors + 1; $display("FAIL score=%0d expected 440", dut.score); end
        if (dut.lives !== 2'd1)    begin errors = errors + 1; $display("FAIL lives=%0d expected 1", dut.lives); end
        press_c;
        expect_state(S_TITLE, "back to title");

        // game over path: three wrong answers on Q1
        sw = 4'd0;
        press_c;
        repeat (3) begin press_l; press_c; press_c; end
        expect_state(S_END, "game over");
        if (dut.lives !== 2'd0) begin errors = errors + 1; $display("FAIL lives=%0d expected 0", dut.lives); end

        $display("tb_game : %0d errors -> %s", errors, errors == 0 ? "PASS" : "FAIL");
        $finish;
    end

    initial begin
        #200_000_000;
        $display("tb_game : TIMEOUT FAIL");
        $finish;
    end
endmodule
