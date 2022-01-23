# project setting
puts [file dirname [info script]]

set project_directory   [file dirname [info script]]
cd $project_directory

# set project_name
set project_name $env(PRJ_NAME)
set board_part   $env(BOARD_PART)
set device_part  $env(DEVICE_PART)


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



# create block design
source [file join ".." $vivado_version "design_1.tcl"]
regenerate_bd_layout
save_bd_design

# xci
#add_files -norecurse /home/ryuji/git-work/jelly_develop/projects/ultra96v2_imx219_hls_sample/ip/vivado2021.2/mipi_dphy_cam/mipi_dphy_cam.xci
add_files -norecurse [file join "../../ip" $vivado_version "mipi_dphy_cam/mipi_dphy_cam.xci"]


# HLS
set_property  ip_repo_paths ../../hls [current_project]
update_ip_catalog

create_ip -name video_filter -vendor xilinx.com -library hls -version 1.0 -module_name video_filter_0
generate_target all [get_files ultra96v2_imx219_hls_sample_tcl.srcs/sources_1/ip/video_filter_0/video_filter_0.xci]


# add source file
proc add_src_file {fileset_name library_name file_type file_name} {
    set file    [file normalize $file_name]
    set fileset [get_filesets   $fileset_name] 
    add_files -norecurse -fileset $fileset $file
    set file_obj [get_files -of_objects $fileset $file]
    set_property "file_type" $file_type $file_obj
    set_property "library"   $library_name $file_obj
}

add_src_file sources_1 WORK "SystemVerilog" ../../rtl/image_processing.sv
add_src_file sources_1 WORK "SystemVerilog" ../../rtl/ultra96v2_imx219_hls_sample.sv
add_src_file sources_1 WORK "SystemVerilog" ../../rtl/video_filter_hls.sv
add_src_file sources_1 WORK "verilog"       ../../../../rtl/bus/jelly_axi4l_to_wishbone.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/bus/jelly_axi4_read_nd.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/bus/jelly_axi4_read.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/bus/jelly_axi4_read_width_convert.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/bus/jelly_axi4s_fifo.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/bus/jelly_axi4s_fifo_width_convert.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/bus/jelly_axi4s_width_convert.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/bus/jelly_axi4_write_nd.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/bus/jelly_axi4_write.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/bus/jelly_axi4_write_width_convert.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/dma/jelly_buffer_allocator.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/dma/jelly_buffer_manager.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/dma/jelly_dma_stream_read.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/dma/jelly_dma_stream_write.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/dma/jelly_dma_video_read.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/dma/jelly_dma_video_write.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_axi4s_img.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_axi4s_insert_blank.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_axi4s_to_img.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_blk_buffer.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_color_matrix_core.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_color_matrix.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_delay.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_demosaic_acpi_core.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_demosaic_acpi_g_core.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_demosaic_acpi_g_unit.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_demosaic_acpi_rb_core.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_demosaic_acpi_rb_unit.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_demosaic_acpi.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_gamma_correction_core.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_gamma_correction.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_gaussian_3x3_core.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_gaussian_3x3_unit.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_gaussian_3x3.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_line_buffer.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_pixel_buffer.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_selector_core.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_selector.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/image/jelly_img_to_axi4s.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_address_align_split.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_address_generator_nd.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_address_generator.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_address_width_convert.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_buffer_arbiter.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_capacity_async.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_capacity_buffer.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_capacity_size.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_data_async.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_data_delay.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_data_ff_pack.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_data_ff.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_data_shift_register_lut.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_data_split_pack2.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_data_split_pack.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_data_width_converter.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_demultiplexer.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_fifo_async_fwtf.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_fifo_async.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_fifo_fwtf.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_fifo_generic_fwtf.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_fifo_pack.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_fifo_ram.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_fifo_read_fwtf.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_fifo_shifter.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_fifo.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_func_binary_to_graycode.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_func_graycode_to_binary.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_func_pack.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_func_unpack.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_multiplexer.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_param_update_master.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_param_update_slave.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_pipeline_control.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_pipeline_insert_ff.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_ram_simple_dualport.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_ram_singleport.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_signal_transfer_async.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_signal_transfer_sync.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_signal_transfer.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_stream_add_syncflag.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_stream_gate.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_stream_width_convert_pack.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/library/jelly_stream_width_convert.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/math/jelly_fixed_matrix3x4.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/primitive/jelly_mul_add3.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/primitive/jelly_mul_add_dsp48e1.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/video/jelly_mipi_csi2_rx_low_layer.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/video/jelly_mipi_csi2_rx_raw10.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/video/jelly_mipi_csi2_rx.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/video/jelly_mipi_ecc24.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/video/jelly_mipi_rx_lane_recv.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/video/jelly_mipi_rx_lane_sync.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/video/jelly_mipi_rx_lane.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/video/jelly_video_format_regularizer_core.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/video/jelly_video_format_regularizer.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/video/jelly_vout_axi4s.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/video/jelly_vsync_adjust_de_core.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/video/jelly_vsync_adjust_de.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/video/jelly_vsync_generator_core.v
add_src_file sources_1 WORK "verilog"       ../../../../rtl/video/jelly_vsync_generator.v

set_property top ultra96v2_imx219_hls_sample [current_fileset]


# add constrain file
add_files    -fileset constrs_1 -norecurse "../../constrain/xdc/top.xdc"
add_files    -fileset constrs_1 -norecurse "../../constrain/xdc/debug.xdc"
set_property target_constrs_file "../../constrain/xdc/debug.xdc" [current_fileset -constrset]


