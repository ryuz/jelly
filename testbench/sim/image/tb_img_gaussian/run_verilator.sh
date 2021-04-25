#! /bin/bash -eu

rm -fr obj_dir
verilator -f verilator_cmd.txt
obj_dir/Vtb_verilator
