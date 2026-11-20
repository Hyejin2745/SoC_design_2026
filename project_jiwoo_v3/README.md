# Karnaugh Gate Quiz (Nexys4 DDR, Verilog)

카르노 맵(K-map)을 보고 숨겨진 논리 게이트를 맞히는 퀴즈(레벨 1)와, MUX 선택 신호를 조절해 목표 숫자를 출력시키는 퀴즈(레벨 2)를 FPGA(Nexys4 DDR)에서 VGA 화면으로 즐기는 게임입니다.
프레임 버퍼 없이 좌표마다 문자·도형을 조합 논리로 만들어 VGA(640x480@60Hz)로 내보냅니다. 클럭은 100MHz 하나만 쓰고, 느린 동작은 enable 펄스로 만듭니다.

## 게임 규칙

총 5문제, 목숨 3개. 정답 확인은 중앙 버튼(BTNC)으로 제출합니다.

| 레벨 | 문제 | 내용 | 조작 |
|---|---|---|---|
| 1 | Q1~Q3 | 화면의 K-map(2x2)을 보고 게이트를 맞힘 (정답: AND, NOR, XOR) | `BTNU`=AND, `BTNL`=OR, `BTNR`=XOR, `SW0` 올리면 NOT(반전) |
| 2 | Q4 | 8:1 MUX 하나. 입력 번호 = `{A,B,C}` (A가 상위 비트) | `SW3`=A, `SW2`=B, `SW1`=C |
| 2 | Q5 | 4:1 MUX 두 개(선택 A,B 공통) + 2:1 MUX 하나(선택 C) | 〃 |

- 제출/다음 화면: `BTNC` (레벨 2에서는 `SW4`를 올려도 됨)
- 점수: 레벨 1은 오답 없이 100점, 한 번 틀리면 70점, 두 번 이상 40점 / 레벨 2는 항상 100점
- 7세그: `AN7`=레벨, `AN6`=문제 번호, `AN3`=목숨, `AN2~0`=점수
- LED: `led_x[2:0]`=목숨, `led_x[3]`=제출 가능, `led_y`(RGB)=상태(파랑 풀이 중 / 초록 정답·클리어 / 빨강 오답·게임오버)
- 리셋: `CPU_RESETN` (누르면 0)

## 디렉터리

```
rtl/          Verilog 소스 (top: top_board)
sim/          testbench (tb_game, tb_gate_unit, tb_vga_sync), run_sim.bat
scripts/      create_project.tcl, gen_font.py, gen_sprite.py, check_text_len.py
constraints/  Nexys-4-DDR-Master.xdc
project_jiwoo.xpr   Vivado 프로젝트
```

## 모듈 연결

```
top_board
 ├ 입력   sync_ff ─ debounce ─ onepulse        (버튼 4개 + SW4)
 ├ 타이밍 clk_en                               (en25: VGA 픽셀, en1k: 디바운스·7세그 스캔)
 ├ 게임   control_fsm ⇄ score_unit
 │        puzzle_rom ─┬ answer_reg, kmap_val ×2 ─ (게이트 일치 비교)   레벨 1
 │                    └ MUX 선택 로직 (top_board 안)                   레벨 2
 ├ 화면   vga_sync ─ renderer ─┬ text_gen ─ font_rom
 │                             └ shape_gen ─ gate_sprite
 └ 출력   seg7_driver ← bin2bcd,  status_led
```

### 모듈 설명

| 파일 | 역할 |
|---|---|
| `top_board.v` | 최상위. 모든 모듈을 연결하고, 레벨 2의 MUX 계산(`mux_up/low/8/out`)과 정답 판정(`match`, `ans_ok`), LED·7세그 배치를 담당 |
| `sync_ff.v` | 외부 입력을 FF 2단으로 클럭에 동기화 |
| `clk_en.v` | `en25`(25MHz)와 `en1k`(1kHz) enable 펄스 생성 |
| `debounce.v` | 1kHz로 샘플링해 STABLE(10)번 연속 같은 값일 때만 출력 변경 |
| `onepulse.v` | 입력이 0→1일 때 1클럭 펄스 |
| `control_fsm.v` | 게임 흐름 Moore FSM: `TITLE(0) → INIT(1) → ANSWER(5) → CORRECT(7) / WRONG(8) → END(9)`. 점수·목숨은 상태 진입 첫 클럭에만 갱신(`entering`) |
| `score_unit.v` | 문제 번호 `qnum`(0~4), 레벨, 목숨, 점수, 최고점, 문제별 오답 횟수 |
| `puzzle_rom.v` | 문제 번호로 고르는 고정 ROM (정답 게이트 코드, MUX 입력값 `d0~d3`/`e0~e3`, 목표 숫자) |
| `answer_reg.v` | 플레이어가 고른 게이트 래치 (`{NOT, base}`, 미선택이면 `111`) |
| `gate_unit.v` | 3비트 코드(`[2]`=반전, `[1:0]`=AND/OR/XOR)로 종류가 정해지는 2입력 게이트 |
| `kmap_val.v` | 게이트 하나의 2x2 진리표 `val[{A,B}]`. 화면의 K-map과 정답 비교가 같은 값을 사용 |
| `vga_sync.v` | 800x525 타이밍, 좌표 `x,y`, `hs/vs/active` |
| `renderer.v` | text > shape > background 순으로 합성하는 3단 파이프라인 (문자·도형 저장 → font_rom 읽기 → 색 선택) |
| `text_gen.v` | 80x30 문자 격자에서 `(col,row)`마다 ASCII 문자와 색 속성을 결정 (모든 화면 문구) |
| `shape_gen.v` | 도형 레이어: 게이트 기호·입력선·NOT 버블·K-map 칸(레벨 1), MUX 도형·배선·선택 경로 강조(레벨 2), 정답/오답 테두리 |
| `gate_sprite.v` | AND/OR/XOR 외곽선 비트맵 (`gen_sprite.py`로 생성) |
| `font_rom.v` | 8x16 폰트 (`gen_font.py`로 생성, `text_gen.v`에 나오는 글자만 포함) |
| `seg7_driver.v` | 8자리 7세그 다중화 구동 (0~9) |
| `bin2bcd.v` | Double-Dabble 방식 10비트 이진수 → 3자리 BCD |
| `status_led.v` | RGB LED 상태 표시 (1/16 밝기 PWM) |

상태 번호(0,1,5,7,8,9)는 `control_fsm`, `text_gen`, `shape_gen`, `status_led`가 각자 `localparam`으로 공유하므로 상태를 바꿀 때는 네 파일을 같이 고쳐야 합니다.

## 수정 가이드

- **문제 바꾸기**: `puzzle_rom.v`만 수정. 문제 수를 바꾸면 `score_unit.v`의 `last_q`·`level` 경계, `text_gen.v`의 `Q n/5` 문구, `top_board.v`의 `mode8`(`qnum == 3`)도 함께 확인
- **화면 문구 바꾸기**: `text_gen.v` 수정 후 `python scripts/check_text_len.py`(문자열 길이 검사)와 `python scripts/gen_font.py`(새 글자가 생기면 폰트 재생성)를 실행
- **게이트 기호 바꾸기**: `scripts/gen_sprite.py` 수정 후 실행해 `gate_sprite.v` 재생성 (손으로 편집하지 않음)
- **스위치/핀 배치**: `top_board.v` 상단 포트와 `constraints/Nexys-4-DDR-Master.xdc`를 함께 수정

## 빌드 / 테스트

- 프로젝트 새로 만들기: Vivado Tcl 콘솔에서 `source scripts/create_project.tcl` (part `xc7a100ticsg324-1L`, top `top_board`)
- 테스트벤치: `sim/tb_game.v`(한 판 전체 시나리오, 예상 점수 470), `tb_gate_unit.v`(게이트 진리표), `tb_vga_sync.v`(VGA 타이밍). `sim/run_sim.bat`로 xsim에서 실행할 수 있음(Vivado 경로는 `VIVADO_BIN`으로 지정)
