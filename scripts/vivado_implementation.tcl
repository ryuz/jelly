set project_directory .
#set project_directory   [file dirname [info script]]
#cd $project_directory

set project_name $env(PRJ_NAME)

open_project [file join $project_directory $project_name]

launch_runs synth_1
wait_on_run synth_1

launch_runs impl_1
wait_on_run impl_1

launch_runs impl_1 -to_step write_bitstream -job 4
wait_on_run impl_1

close_project
