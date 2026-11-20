`timescale 1ns / 1ps
// gate_unit : 6 codes x 4 inputs = 24 cases compared with expected values; 0 mismatches = pass
module tb_gate_unit;
    reg        a, b;
    reg  [2:0] code;
    wire       y;
    integer    errors, n;
    reg        exp;

    gate_unit dut (a, b, code, y);

    // expected values (truth table written out by hand)
    function expected;
        input [2:0] c;
        input       ia, ib;
        begin
            case (c)
                3'b000: expected = ia & ib;          // AND
                3'b001: expected = ia | ib;          // OR
                3'b010: expected = ia ^ ib;          // XOR
                3'b100: expected = ~(ia & ib);       // NAND
                3'b101: expected = ~(ia | ib);       // NOR
                3'b110: expected = ~(ia ^ ib);        // XNOR
                default: expected = 1'bx;
            endcase
        end
    endfunction

    integer ci, ai;
    reg [2:0] codes [0:5];

    initial begin
        errors = 0; n = 0;
        codes[0] = 3'b000; codes[1] = 3'b001; codes[2] = 3'b010;
        codes[3] = 3'b100; codes[4] = 3'b101; codes[5] = 3'b110;
        for (ci = 0; ci < 6; ci = ci + 1)
            for (ai = 0; ai < 4; ai = ai + 1) begin
                code = codes[ci];
                {a, b} = ai[1:0];
                #1;
                exp = expected(code, a, b);
                n = n + 1;
                if (y !== exp) begin
                    errors = errors + 1;
                    $display("FAIL code=%b a=%b b=%b y=%b exp=%b", code, a, b, y, exp);
                end
            end
        $display("tb_gate_unit : %0d cases, %0d errors -> %s", n, errors, errors == 0 ? "PASS" : "FAIL");
        $finish;
    end
endmodule
