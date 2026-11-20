`timescale 1ns / 1ps
// circuit_eval : a reference model (function) written inside the testbench is compared against the DUT:
//   216 gate combinations x 16 inputs, and level 1 (single) mode, all compared
module tb_circuit_eval;
    reg  [3:0] in_vec;
    reg  [2:0] g1, g2, g3;
    reg        single;
    wire       f;
    integer    errors, n;

    circuit_eval dut (
        in_vec,                     // in_vec
        g1,                         // g1
        g2,                         // g2
        g3,                         // g3
        single,                     // single
        f                           // f
    );

    // ---- reference model ------------------------------------------------------
    function ref_gate;
        input [2:0] code;
        input       a, b;
        reg         r;
        begin
            case (code[1:0])
                2'd0:    r = a & b;
                2'd1:    r = a | b;
                default: r = a ^ b;
            endcase
            ref_gate = code[2] ? ~r : r;
        end
    endfunction

    function ref_f;
        input [3:0] v;
        input [2:0] c1, c2, c3;
        input       sgl;
        reg         n1, n2, o3;
        begin
            n1 = ref_gate(c1, v[3], v[2]);
            n2 = ref_gate(c2, v[1], v[0]);
            o3 = ref_gate(c3, n1, n2);
            ref_f = sgl ? n1 : o3;
        end
    endfunction

    reg [2:0] codes [0:5];
    integer i1, i2, i3, iv;
    reg exp;

    task check;
        begin
            #1;
            exp = ref_f(in_vec, g1, g2, g3, single);
            n = n + 1;
            if (f !== exp) begin
                errors = errors + 1;
                if (errors < 10)
                    $display("FAIL v=%b g=%b %b %b single=%b f=%b exp=%b",
                             in_vec, g1, g2, g3, single, f, exp);
            end
        end
    endtask

    initial begin
        errors = 0; n = 0;
        codes[0] = 3'b000; codes[1] = 3'b001; codes[2] = 3'b010;
        codes[3] = 3'b100; codes[4] = 3'b101; codes[5] = 3'b110;
        single = 0;

        // 216 x 16
        for (i1 = 0; i1 < 6; i1 = i1 + 1)
         for (i2 = 0; i2 < 6; i2 = i2 + 1)
          for (i3 = 0; i3 < 6; i3 = i3 + 1)
           for (iv = 0; iv < 16; iv = iv + 1) begin
               g1 = codes[i1]; g2 = codes[i2]; g3 = codes[i3];
               in_vec = iv[3:0];
               single = 0;
               check;
               single = 1;              // level 1: F = n1
               check;
           end

        $display("tb_circuit_eval : %0d cases, %0d errors -> %s", n, errors, errors == 0 ? "PASS" : "FAIL");
        $finish;
    end
endmodule
