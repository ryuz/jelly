
set hls_target $env(HLS_TARGET)
set hls_solution $env(HLS_SOLUTION)

open_project $hls_target

# source files
set src_flag "-Isrc"
add_files "src/divider.cpp" -cflags $src_flag

# testbanch
set tb_flag "-Isrc -Itestbench"
add_files -tb "testbench/tb_divider.cpp" -cflags $tb_flag

open_solution $hls_solution

close_solution
close_project
