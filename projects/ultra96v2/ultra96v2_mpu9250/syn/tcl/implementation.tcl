
puts [file dirname [info script]]

set project_directory   [file dirname [info script]]
set project_name        "ultra96v2_mpu9250_tcl"

cd $project_directory

open_project [file join $project_directory $project_name]

launch_runs synth_1
wait_on_run synth_1

launch_runs impl_1
wait_on_run impl_1

launch_runs impl_1 -to_step write_bitstream -job 4
wait_on_run impl_1

close_project