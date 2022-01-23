
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

# source files
set src_flag "-Isrc"
add_files "src/video_filter.cpp" -cflags $src_flag

# testbanch
set tb_flag "-Isrc -Itestbench"
add_files -tb "testbench/tb_video_filter.cpp" -cflags $tb_flag

open_solution $hls_solution

close_solution
close_project
