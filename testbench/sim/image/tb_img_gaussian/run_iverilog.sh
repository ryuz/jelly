#! /bin/bash -eu

iverilog -o tb_img_gaussian.vvp -s tb_img_gaussian -c iverilog_cmd.txt -DIVERILOG
vvp tb_img_gaussian.vvp
