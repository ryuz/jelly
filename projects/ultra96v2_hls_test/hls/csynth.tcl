
set hls_target $env(HLS_TARGET)
set hls_solution $env(HLS_SOLUTION)
set device_part $env(DEVICE_PART)
set clock_period $env(CLOCK_PERIOD)

open_project $hls_target
open_solution $hls_solution

set_top $hls_target
set_part $device_part
create_clock -period $clock_period -name default
source "directives.tcl"

csynth_design
export_design -format ip_catalog

close_solution
close_project
