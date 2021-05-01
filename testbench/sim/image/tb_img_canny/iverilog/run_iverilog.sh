#! /bin/bash -eu

iverilog -o tb_img_canny.vvp -s tb_img_canny -c iverilog_cmd.txt -DIVERILOG
vvp tb_img_canny.vvp
