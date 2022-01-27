
# environments
set hls_target $env(HLS_TARGET)
set hls_solution $env(HLS_SOLUTION)
set device_part $env(DEVICE_PART)
set clock_period $env(CLOCK_PERIOD)
set source_flags $env(SOURCE_FLAGS)
set testbench_flags $env(TESTBENCH_FLAGS)
set sources     [split $env(SOURCES) " "]
set testbenches [split $env(TESTBENCHS) " "]

# create project
open_project $hls_target
open_solution $hls_solution

set_top $hls_target
set_part $device_part
create_clock -period $clock_period -name default
source "directives.tcl"

# source files
foreach fname $sources {
    add_files $fname -cflags $source_flags
}

# testbanch
foreach fname $testbenches {
    add_files -tb $fname -cflags $testbench_flags
}

# open solution
open_solution $hls_solution

# close
close_solution
close_project
