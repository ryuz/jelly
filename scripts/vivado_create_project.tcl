
# project directory
set project_directory .
#set project_directory   [file dirname [info script]]
#cd $project_directory

# set project environments
set project_name $env(PRJ_NAME)
set top_module   $env(TOP_MODULE)
set board_part  [expr {[info exists env(BOARD_PART) ] ? $env(BOARD_PART)  : ""}]
set device_part [expr {[info exists env(DEVICE_PART)] ? $env(DEVICE_PART) : ""}]
set sources     [expr {[info exists env(SOURCES)    ] ? [split $env(SOURCES)    " "] : {}}]
set defines     [expr {[info exists env(DEFINES)    ] ? [split $env(DEFINES)    " "] : {}}]
set ip_cores    [expr {[info exists env(IP_CORES)   ] ? [split $env(IP_CORES)   " "] : {}}]
set bd_scripts  [expr {[info exists env(BD_SCRIPTS) ] ? [split $env(BD_SCRIPTS) " "] : {}}]
set hls_ip      [expr {[info exists env(HLS_IP)     ] ? [split $env(HLS_IP)     " "] : {}}]
set constrains  [expr {[info exists env(CONSTRAINS) ] ? [split $env(CONSTRAINS) " "] : {}}]
set synth_args_more [expr {[info exists env(SYNTH_ARGS_MORE)] ? $env(SYNTH_ARGS_MORE) : ""}]

# add borad repository path
if       { [string first "Linux"   $::tcl_platform(os)] != -1 } {
    set_param board.repoPaths [concat [file join $::env(HOME) {.Xilinx/Vivado/} [version -short] {xhub/board_store}] [get_param board.repoPaths]]
} elseif { [string first "Windows" $::tcl_platform(os)] != -1 } {
    set_param board.repoPaths [concat [file join $::env(APPDATA) {Xilinx/Vivado/} [version -short] {xhub/board_store}] [get_param board.repoPaths]]
}

# get vivado version
set current_vivado_version [version -short]
set current_vivado_version_major [string range $current_vivado_version 0 5]
set current_vivado_version_year [string range $current_vivado_version 0 3]

# set synth setting
append vivado_version   "vivado" $current_vivado_version_major
append synth_1_flow     "Vivado Synthesis " $current_vivado_version_year
append synth_1_strategy "Vivado Synthesis Defaults"
append impl_1_flow      "Vivado Implementation " $current_vivado_version_year
append impl_1_strategy  "Vivado Implementation Defaults"


# create project
create_project -force $project_name $project_directory

# get latest board part
set latest_board_part [get_board_parts -quiet -latest_file_version $board_part]

# set board_part or device_part
if       {[info exists board_part ] && [string equal $latest_board_part  "" ] == 0} {
    set_property "board_part"     $latest_board_part [current_project]
} elseif {[info exists device_part] && [string equal $device_part "" ] == 0} {
    set_property "part"           $device_part       [current_project]
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


# HLS
if {[llength $hls_ip] > 0} {
    set hls_dir   $env(HLS_DIR)
    set_property  ip_repo_paths $hls_dir [current_project]
    update_ip_catalog

    foreach ipnames $hls_ip {
        set names [split $ipnames ","]
        set ip_name [lindex $names 0]
        set inst_name [lindex $names 1]
        append xci_name $inst_name ".xci"
        append xci_path $project_name ".srcs/sources_1/ip/" $inst_name "/" $xci_name
        create_ip -name $ip_name -vendor xilinx.com -library hls -version 1.0 -module_name $inst_name
        generate_target all [get_files $xci_path]
    }
}

# add source file
foreach fname $sources {
  add_files -fileset sources_1 -norecurse $fname
}

# IP cores
foreach fname $ip_cores {
  add_files -norecurse $fname
}

# add constrain file
foreach fname $constrains {
  add_files -fileset constrs_1 -norecurse $fname
}

# set top module
set_property top $top_module [current_fileset]


# defines
foreach define $defines {
  append synth_args_more " -verilog_define " $define
}

# add option
set synth_args_more [string trim $synth_args_more]
if {[string equal $synth_args_more ""] == 0} {
  set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value $synth_args_more -objects [get_runs synth_1]
}

# create block design
foreach fname $bd_scripts {
    source $fname
    regenerate_bd_layout
    save_bd_design
}
