
set hls_target $env(HLS_TARGET)
set hls_solution $env(HLS_SOLUTION)
set csim_options [split $env(CSIM_OPTIONS) " "]

open_project $hls_target
open_solution $hls_solution

csim_design {*}$csim_options

close_solution
close_project
