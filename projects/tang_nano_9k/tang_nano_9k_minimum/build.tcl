set_device -device_version C GW1NR-LV9QN88PC6/I5
set_option -synthesis_tool gowinsynthesis
set_option -output_base_name top
set_option -use_done_as_gpio 1
add_file -type verilog top.v
add_file -type cst top.cst
run all
