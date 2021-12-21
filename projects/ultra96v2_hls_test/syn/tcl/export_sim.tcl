
puts [file dirname [info script]]
set project_directory   [file dirname [info script]]
cd $project_directory

set project_name $env(PRJ_NAME)

open_project [file join $project_directory $project_name]



#create_ip_run [get_files -of_objects [get_fileset sources_1] /home/ryuji/git-work/jelly_develop/projects/ultra96v2_hls_test/syn/vivado2019.2/ultra96v2_hls_test.srcs/sources_1/ip/divider_0_1/divider_0.xci]
#launch_runs -jobs 4 divider_0_synth_1
#wait_on_run divider_0_synth_1

#export_simulation -of_objects [get_files /home/ryuji/git-work/jelly_develop/projects/ultra96v2_hls_test/syn/vivado2019.2/ultra96v2_hls_test.srcs/sources_1/ip/divider_0_1/divider_0.xci] -directory /home/ryuji/git-work/jelly_develop/projects/ultra96v2_hls_test/syn/vivado2019.2/ultra96v2_hls_test.ip_user_files/sim_scripts -ip_user_files_dir /home/ryuji/git-work/jelly_develop/projects/ultra96v2_hls_test/syn/vivado2019.2/ultra96v2_hls_test.ip_user_files -ipstatic_source_dir /home/ryuji/git-work/jelly_develop/projects/ultra96v2_hls_test/syn/vivado2019.2/ultra96v2_hls_test.ip_user_files/ipstatic -lib_map_path [list {modelsim=/home/ryuji/git-work/jelly_develop/projects/ultra96v2_hls_test/syn/vivado2019.2/ultra96v2_hls_test.cache/compile_simlib/modelsim} {questa=/home/ryuji/git-work/jelly_develop/projects/ultra96v2_hls_test/syn/vivado2019.2/ultra96v2_hls_test.cache/compile_simlib/questa} {ies=/home/ryuji/git-work/jelly_develop/projects/ultra96v2_hls_test/syn/vivado2019.2/ultra96v2_hls_test.cache/compile_simlib/ies} {xcelium=/home/ryuji/git-work/jelly_develop/projects/ultra96v2_hls_test/syn/vivado2019.2/ultra96v2_hls_test.cache/compile_simlib/xcelium} {vcs=/home/ryuji/git-work/jelly_develop/projects/ultra96v2_hls_test/syn/vivado2019.2/ultra96v2_hls_test.cache/compile_simlib/vcs} {riviera=/home/ryuji/git-work/jelly_develop/projects/ultra96v2_hls_test/syn/vivado2019.2/ultra96v2_hls_test.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet

export_simulation -of_objects [get_files ultra96v2_hls_test_tcl.srcs/sources_1/ip/divider_0/divider_0.xci]

# -directory ultra96v2_hls_test_tcl.ip_user_files/sim_scripts \
# -ip_user_files_dir ultra96v2_hls_test_tcl.ip_user_files \
# -ipstatic_source_dir ultra96v2_hls_test_tcl.ip_user_files/ipstatic \
# -lib_map_path [list {modelsim=ultra96v2_hls_test_tcl.cache/compile_simlib/modelsim} \
#  {questa=ultra96v2_hls_test_tcl.cache/compile_simlib/questa} \
#  {ies=ultra96v2_hls_test_tcl.cache/compile_simlib/ies} \
#  {xcelium=ultra96v2_hls_test_tcl.cache/compile_simlib/xcelium} \
#  {vcs=ultra96v2_hls_test_tcl.cache/compile_simlib/vcs} \
#  {riviera=ultra96v2_hls_test_tcl.cache/compile_simlib/riviera} \
#  ] -use_ip_compiled_libs -force -quiet



close_project