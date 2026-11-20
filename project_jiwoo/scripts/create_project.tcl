# Vivado project generator for Black-box Circuit Detective (Nexys4 DDR)
# Usage (Vivado Tcl console):
#   cd E:/intelFPGA/project
#   source scripts/create_project.tcl
set root [file normalize [file join [file dirname [info script]] ..]]

create_project -force bbd_proj [file join $root vivado] -part xc7a100ticsg324-1L

add_files -fileset sources_1 [glob [file join $root rtl *.v]]
set_property top top_board [get_filesets sources_1]

add_files -fileset constrs_1 [file join $root constraints Nexys-4-DDR-Master.xdc]

add_files -fileset sim_1 [glob [file join $root sim tb_*.v]]
set_property top tb_game [get_filesets sim_1]

update_compile_order -fileset sources_1
puts "Project created. Run Synthesis -> Implementation -> Generate Bitstream."
