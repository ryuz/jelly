# project setting
puts [file dirname [info script]]

set project_directory   [file dirname [info script]]
set project_name        "ultra96v2_hls_test_tcl"

cd $project_directory


# add borad repository path
if       { [string first "Linux"   $::tcl_platform(os)] != -1 } {
    set_param board.repoPaths [concat [file join $::env(HOME) {.Xilinx/Vivado/} [version -short] {xhub/board_store}] [get_param board.repoPaths]]
} elseif { [string first "Windows" $::tcl_platform(os)] != -1 } {
    set_param board.repoPaths [concat [file join $::env(APPDATA) {Xilinx/Vivado/} [version -short] {xhub/board_store}] [get_param board.repoPaths]]
}


# version
set current_vivado_version [version -short]
if       { [string first "2019.2" $current_vivado_version] != -1 } {
    set vivado_version   "vivado2019.2"
    set synth_1_flow     "Vivado Synthesis 2019"
    set synth_1_strategy "Vivado Synthesis Defaults"
    set impl_1_flow      "Vivado Implementation 2019"
    set impl_1_strategy  "Vivado Implementation Defaults"
} elseif { [string first "2020.1" $current_vivado_version] != -1 } {
    set vivado_version   "vivado2020.1"
    set synth_1_flow     "Vivado Synthesis 2020"
    set synth_1_strategy "Vivado Synthesis Defaults"
    set impl_1_flow      "Vivado Implementation 2020"
    set impl_1_strategy  "Vivado Implementation Defaults"
} elseif { [string first "2021.2" $current_vivado_version] != -1 } {
    set vivado_version   "vivado2021.2"
    set synth_1_flow     "Vivado Synthesis 2021"
    set synth_1_strategy "Vivado Synthesis Defaults"
    set impl_1_flow      "Vivado Implementation 2021"
    set impl_1_strategy  "Vivado Implementation Defaults"
} else {
    puts "ERROR: mismatch vivado version."
    return 1
}


# create project
create_project -force $project_name $project_directory

#set board_part "avnet.com:ultra96v2:part0:1.1"
set board_part [get_board_parts -quiet -latest_file_version "avnet.com:ultra96v2*"]
set device_part "xczu3eg-sbva484-1-i"

set_property "part"           $device_part     [current_project]
set_property "board_part"     $board_part      [current_project]

if       {[info exists board_part ] && [string equal $board_part  "" ] == 0} {
    set_property "board_part"     $board_part      [current_project]
} elseif {[info exists device_part] && [string equal $device_part "" ] == 0} {
    set_property "part"           $device_part     [current_project]
} else {
    puts "ERROR: Please set board_part or device_part."
    return 1
}

set_property "default_lib"        "xil_defaultlib" [current_project]
set_property "simulator_language" "Mixed"          [current_project]
set_property "target_language"    "verilog"        [current_project]

# Create fileset "sources_1"
if {[string equal [get_filesets -quiet sources_1] ""]} {
    create_fileset -srcset sources_1
}

# Create fileset "constrs_1"
if {[string equal [get_filesets -quiet constrs_1] ""]} {
    create_fileset -constrset constrs_1
}

# Create fileset "sim_1"
if {[string equal [get_filesets -quiet sim_1] ""]} {
    create_fileset -simset sim_1
}

# create run "synth_1" and set property
if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 -flow $synth_1_flow -strategy $synth_1_strategy -constrset constrs_1
} else {
    set_property flow     $synth_1_flow     [get_runs synth_1]
    set_property strategy $synth_1_strategy [get_runs synth_1]
}
current_run -synthesis [get_runs synth_1]

# create run "impl_1" and set property
if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run -name impl_1 -flow $impl_1_flow -strategy $impl_1_strategy -constrset constrs_1 -parent_run synth_1
} else {
    set_property flow     $impl_1_flow      [get_runs impl_1]
    set_property strategy $impl_1_strategy  [get_runs impl_1]
}
current_run -implementation [get_runs impl_1]



# create block design
source [file join ".." $vivado_version "design_1.tcl"  ]
regenerate_bd_layout
save_bd_design
    
# HLS
set_property  ip_repo_paths ../../hls [current_project]
update_ip_catalog

create_ip -name divider -vendor xilinx.com -library hls -version 1.0 -module_name divider_0


# add source file
proc add_verilog_file {fileset_name library_name file_name} {
    set file    [file normalize $file_name]
    set fileset [get_filesets   $fileset_name] 
    add_files -norecurse -fileset $fileset $file
    set file_obj [get_files -of_objects $fileset $file]
    set_property "file_type" "verilog" $file_obj
    set_property "library"   $library_name $file_obj
}

add_verilog_file sources_1 WORK ../../rtl/ultra96v2_hls_test.v
add_verilog_file sources_1 WORK ../../rtl/test_hls.v
add_verilog_file sources_1 WORK ../../../../rtl/bus/jelly_axi4l_to_wishbone.v

set_property top ultra96v2_hls_test [current_fileset]


# add constrain file
add_files    -fileset constrs_1 -norecurse "../../constrain/xdc/top.xdc"
add_files    -fileset constrs_1 -norecurse "../../constrain/xdc/debug.xdc"
set_property target_constrs_file "../../constrain/xdc/debug.xdc" [current_fileset -constrset]


