
set hls_target $env(HLS_TARGET)
set hls_solution $env(HLS_SOLUTION)

open_project $hls_target
open_solution $hls_solution

cosim_design -trace_level all -tool xsim -wave_debug

close_solution
close_project
