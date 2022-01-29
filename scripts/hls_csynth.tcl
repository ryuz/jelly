
set hls_target $env(HLS_TARGET)
set hls_solution $env(HLS_SOLUTION)

open_project $hls_target
open_solution $hls_solution

csynth_design
export_design -format ip_catalog

close_solution
close_project
