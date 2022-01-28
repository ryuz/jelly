
set hls_target $env(HLS_TARGET)
set hls_solution $env(HLS_SOLUTION)
set cosim_options [split $env(COSIM_OPTIONS) " "]

open_project $hls_target
open_solution $hls_solution

cosim_design {*}$cosim_options

close_solution
close_project
