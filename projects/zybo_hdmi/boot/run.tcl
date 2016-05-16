connect arm hw
rst -slcr
fpga -f top.bit
source ps7_init.tcl
ps7_init
ps7_post_config
