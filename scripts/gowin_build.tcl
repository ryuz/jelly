
# device_version
set device_name $::env(DEVICE_NAME)
if {[info exists ::env(DEVICE_VERSION)]} {
    set device_version $::env(DEVICE_VERSION)
    set_device -device_version $device_version $device_name
} else {
#   set device_version "C"
    set_device $device_name
}

# synthesis_tool
if {[info exists ::env(SYNTHESIS_TOOL)]} {
    set synthesis_tool $::env(SYNTHESIS_TOOL)
} else {
    set synthesis_tool "gowinsynthesis"
}
set_option -synthesis_tool $synthesis_tool

# output_base_name
if {[info exists ::env(OUTPUT_BASE_NAME)]} {
    set_option -output_base_name $::env(OUTPUT_BASE_NAME)
}

# verilog_std
if {[info exists ::env(VERILOG_STD)]} {
    set verilog_std $::env(VERILOG_STD)
} else {
    set verilog_std "sysv2017"
}
set_option -verilog_std $verilog_std

# use_done_as_gpio
if {[info exists ::env(USE_DONE_AS_GPIO)]} {
    set use_done_as_gpio $::env(USE_DONE_AS_GPIO)
} else {
    set use_done_as_gpio "1"
}
set_option -use_done_as_gpio $use_done_as_gpio

# use_cpu_as_gpio
if {[info exists ::env(USE_CPU_AS_GPIO)]} {
    set use_cpu_as_gpio $::env(USE_CPU_AS_GPIO)
} else {
    set use_cpu_as_gpio "1"
}
set_option -use_cpu_as_gpio $use_cpu_as_gpio


# top_module
if {[info exists ::env(TOP_MODULE)]} {
    set_option -top_module $::env(TOP_MODULE)
}

# verilog files
if {[info exists ::env(VLOG_SOURCES)]} {
    foreach fname [split $::env(VLOG_SOURCES) " "] {
        add_file -type verilog $fname
    }
}

# sdc files
if {[info exists ::env(SDC_SOURCES)]} {
    foreach fname [split $::env(SDC_SOURCES) " "] {
        add_file -type sdc $fname
    }
}

# cst files
if {[info exists ::env(CST_SOURCES)]} {
    foreach fname [split $::env(CST_SOURCES) " "] {
        add_file -type cst $fname
    }
}

# run
run all
