# Run in the Vivado Tcl console with the project open:
#   source E:/Vivado/project_jiwoo/scripts/vivado_fix_settings.tcl
# Part (xc7a100ticsg324-1L) and constraints/Nexys-4-DDR-Master.xdc are fixed and not touched here.
set_property top top_board [get_filesets sources_1]
set_property top tb_demo   [get_filesets sim_1]
foreach f [get_files -of_objects [get_filesets sources_1] *tb_*.v] {
    set_property used_in_synthesis false $f
    set_property used_in_implementation false $f
}
set_property -name {xsim.simulate.runtime} -value {-all} -objects [get_filesets sim_1]
update_compile_order -fileset sources_1
reset_run synth_1
puts "done: part=[get_property part [current_project]] top=[get_property top [get_filesets sources_1]]"
