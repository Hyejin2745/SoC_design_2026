# Karnaugh Gate Quiz (Nexys4 DDR)

VGA 화면의 카르노 맵과 MUX 그림을 보고 푸는 5문제 퀴즈 (Verilog, Vivado 2023.1).

- Level 1 (Q1-Q3): 카르노 맵을 보고 숨은 게이트(AND, NOR, XOR) 맞히기
  - BTNU = AND, BTNL = OR, BTNR = XOR, SW0 = NOT, BTNC = 제출/다음
- Level 2 (Q4-Q5): MUX 선택 신호 A, B, C 맞히기
  - Q4: 8:1 MUX, Q5: 4:1 MUX 2개(같은 A,B) + 2:1 MUX(C)
  - SW3 = A, SW2 = B, SW1 = C, SW4 올리기 = 제출/다음 (BTNC도 가능)

폴더: `rtl/` 소스, `sim/` testbench, `constraints/` xdc, `scripts/` 프로젝트 생성/도구.
프로젝트 생성: Vivado Tcl 콘솔에서 `source scripts/create_project.tcl`
