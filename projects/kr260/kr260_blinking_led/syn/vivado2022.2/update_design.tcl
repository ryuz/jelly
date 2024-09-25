cd [get_property DIRECTORY [current_project]]
remove_files -fileset utils_1 project_1/project_1.srcs/utils_1/imports/synth_1/kr260_blinking_led.dcp
remove_files kr260_blinking_led.srcs/sources_1/bd/design_1/design_1.bd
source design_1.tcl
