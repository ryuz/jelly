#! /bin/bash -eu

iverilog -o tb_texture_sampler.vvp -s tb_texture_sampler -c tb_texture_sampler.txt -DIVERILOG
vvp tb_texture_sampler.vvp
