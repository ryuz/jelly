set_device -device_version C GW1NR-LV9QN88PC6/I5
set_option -synthesis_tool gowinsynthesis
set_option -output_base_name tang_nano_9k_blinking_led
set_option -verilog_std sysv2017 -use_done_as_gpio 1
add_file -type verilog tang_nano_9k_blinking_led.v
add_file -type cst tang_nano_9k_blinking_led.cst
run all
