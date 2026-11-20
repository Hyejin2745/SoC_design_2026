`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// sound_gen : correct / wrong / clear sound effects (3-note melody, PWM output)
//   snd_sel : 0 none, 1 correct (C-E-G), 2 wrong (falling notes), 3 clear (C-G-high C)
//   Playback starts the moment snd_sel changes to a non-zero value.
//   tick1m : 1MHz enable (pitch), tick1k : 1kHz enable (note length)
//   To keep the sound from being too loud, only 25% of the high interval is turned on.
//------------------------------------------------------------------------------
module sound_gen #(
    parameter NOTE_MS = 150
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       tick1m,
    input  wire       tick1k,
    input  wire [1:0] snd_sel,
    output reg        pwm,
    output wire       aud_sd
);
    assign aud_sd = 1'b1;     // amplifier on

    reg [1:0]  prev;
    reg        playing;
    reg [1:0]  kind;
    reg [1:0]  note;
    reg [8:0]  dur;
    reg [11:0] cnt;
    reg        tone;
    reg [5:0]  car;

    // half period (us). 523Hz=956, 659Hz=759, 784Hz=638, 1047Hz=478 ...
    function [11:0] hp;
        input [1:0] k;
        input [1:0] n;
        case ({k, n})
            4'b0100: hp = 12'd956;    // correct: C E G
            4'b0101: hp = 12'd759;
            4'b0110: hp = 12'd638;
            4'b1000: hp = 12'd1515;   // wrong: 330Hz 262Hz 196Hz
            4'b1001: hp = 12'd1908;
            4'b1010: hp = 12'd2551;
            4'b1100: hp = 12'd956;    // clear: C G high C
            4'b1101: hp = 12'd638;
            4'b1110: hp = 12'd478;
            default: hp = 12'd1000;
        endcase
    endfunction

    always @(posedge clk) begin
        car <= car + 6'd1;
        if (rst) begin
            prev    <= 2'd0;
            playing <= 1'b0;
            kind    <= 2'd0;
            note    <= 2'd0;
            dur     <= 9'd0;
            cnt     <= 12'd0;
            tone    <= 1'b0;
            pwm     <= 1'b0;
            car     <= 6'd0;      // without this reset car stays X in simulation and pwm never toggles
        end else begin
            prev <= snd_sel;
            if (snd_sel != 2'd0 && snd_sel != prev) begin
                kind    <= snd_sel;
                note    <= 2'd0;
                dur     <= 9'd0;
                cnt     <= 12'd0;
                tone    <= 1'b0;
                playing <= 1'b1;
            end else if (playing) begin
                if (tick1m) begin
                    if (cnt >= hp(kind, note) - 12'd1) begin
                        cnt  <= 12'd0;
                        tone <= ~tone;
                    end else begin
                        cnt <= cnt + 12'd1;
                    end
                end
                if (tick1k) begin
                    if (dur == NOTE_MS - 1) begin
                        dur <= 9'd0;
                        if (note == 2'd2) begin
                            playing <= 1'b0;
                            tone    <= 1'b0;
                        end else begin
                            note <= note + 2'd1;
                        end
                    end else begin
                        dur <= dur + 9'd1;
                    end
                end
            end
            pwm <= playing & tone & (car < 6'd16);
        end
    end
endmodule
