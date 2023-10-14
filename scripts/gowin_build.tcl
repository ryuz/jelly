
# environments
set base_name $::env(BASE_NAME)
set device_name $::env(DEVICE_NAME)
set device_version $::env(DEVICE_VERSION)

if {[info exists ::env(CST_SOURCES)]} {
    set vlog_sources  [split $::env(VLOG_SOURCES) " "]
} else {
    set vlog_sources {}
}

if {[info exists ::env(SDC_SOURCES)]} {
    set sdc_sources  [split $::env(SDC_SOURCES) " "]
} else {
    set sdc_sources {}
}

if {[info exists ::env(CST_SOURCES)]} {
    set cst_sources  [split $::env(CST_SOURCES) " "]
} else {
    set cst_sources {}
}

if {[info exists ::env(DEVICE_VERSION)]} {
    set device_version $::env(DEVICE_VERSION)
} else {
    set device_version "C"
}

if {[info exists ::env(VERILOG_STD)]} {
    set verilog_std $::env(VERILOG_STD)
} else {
    set verilog_std "sysv2017"
}

if {[info exists ::env(USE_DONE_AS_GPIO)]} {
    set use_done_as_gpio $::env(USE_DONE_AS_GPIO)
} else {
    set use_done_as_gpio "1"
}


set_device -device_version $device_version $device_name
set_option -synthesis_tool gowinsynthesis
set_option -output_base_name $base_name
set_option -verilog_std $verilog_std
set_option -use_done_as_gpio $use_done_as_gpio

# verilog files
foreach fname $vlog_sources {
    add_file -type verilog $fname
}

# sdc files
foreach fname $sdc_sources {
    add_file -type sdc $fname
}

# cst files
foreach fname $cst_sources {
    add_file -type cst $fname
}

# run
run all
