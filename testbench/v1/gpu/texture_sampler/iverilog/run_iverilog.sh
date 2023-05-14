#! /bin/bash -eu

iverilog -o tb_texture_sampler.vvp -s tb_texture_sampler -c iverilog_cmd.txt -DIVERILOG
vvp tb_texture_sampler.vvp
