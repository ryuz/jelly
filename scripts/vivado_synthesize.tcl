set project_directory .
#set project_directory   [file dirname [info script]]
#cd $project_directory

set project_name $env(PRJ_NAME)
set to_step [expr {[info exists env(TO_STEP)] ? $env(TO_STEP) : "write_bitstream"}]

open_project [file join $project_directory $project_name]

launch_runs synth_1 -job 4
wait_on_run synth_1

close_project
