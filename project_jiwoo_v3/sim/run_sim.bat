@echo off
rem ---------------------------------------------------------------------------
rem  Run all testbenches with the Vivado simulator (xsim).
rem  Usage:  sim\run_sim.bat            (all testbenches)
rem          sim\run_sim.bat tb_game    (one testbench)
rem  Vivado bin folder must be in PATH, or set VIVADO_BIN, or edit the path below.
rem ---------------------------------------------------------------------------
setlocal
if not defined VIVADO_BIN set VIVADO_BIN=E:\Xilinx\Vivado\2023.1\bin
set PATH=%VIVADO_BIN%;%PATH%

set ROOT=%~dp0..
set BUILD=%~dp0build
if not exist "%BUILD%" mkdir "%BUILD%"
cd /d "%BUILD%"

if "%1"=="" (
    set TBS=tb_gate_unit tb_vga_sync tb_game
) else (
    set TBS=%1
)

for %%f in ("%ROOT%\rtl\*.v") do call xvlog "%%f" >nul
for %%f in ("%ROOT%\sim\tb_*.v") do call xvlog "%%f" >nul

for %%t in (%TBS%) do (
    echo ================= %%t =================
    rem --O2 : with the default optimization level xsim fails to link renderer (undefined subprog reference)
    call xelab -debug off --O2 %%t -s %%t_snap >nul
    call xsim %%t_snap -runall | findstr /R "tb_ ok FAIL PASS game final first ----"
)
endlocal
