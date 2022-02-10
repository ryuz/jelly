
# get vivado version
empty:=
space:= $(empty) $(empty)
VIVADO_VERSIONS := $(subst .,$(space),$(subst v,,$(word 2,$(shell vivado -version))))
VIVADO_VERSION  := $(word 1,$(VIVADO_VERSIONS)).$(word 2,$(VIVADO_VERSIONS))

# settings
export PRJ_NAME    = ultra96v2_imx219_hls_sample_tcl
export TOP_MODULE  = ultra96v2_imx219_hls_sample
export BOARD_PART  = avnet.com:ultra96v2*
export DEVICE_PART = xczu3eg-sbva484-1-i

# directories
TOP_DIR = ../../../..
PRJ_DIR = ../..
HLS_DIR = $(PRJ_DIR)/hls

# HLS
HLS_EXPORT_FILE = $(HLS_DIR)/video_filter/solution_1/impl/export.zip

# HLS IP
HLS_IP = video_filter,video_filter_0
export HLS_IP
export HLS_DIR

# sources
SOURCES   = $(PRJ_DIR)/rtl/ultra96v2_imx219_hls_sample.sv
SOURCES  += $(PRJ_DIR)/rtl/image_processing.sv
SOURCES  += $(PRJ_DIR)/rtl/video_filter_hls.sv
SOURCES  += $(TOP_DIR)/rtl/bus/jelly_axi4l_to_wishbone.v
SOURCES  += $(TOP_DIR)/rtl/bus/jelly_axi4_read_nd.v
SOURCES  += $(TOP_DIR)/rtl/bus/jelly_axi4_read.v
SOURCES  += $(TOP_DIR)/rtl/bus/jelly_axi4_read_width_convert.v
SOURCES  += $(TOP_DIR)/rtl/bus/jelly_axi4s_fifo.v
SOURCES  += $(TOP_DIR)/rtl/bus/jelly_axi4s_fifo_width_convert.v
SOURCES  += $(TOP_DIR)/rtl/bus/jelly_axi4s_width_convert.v
SOURCES  += $(TOP_DIR)/rtl/bus/jelly_axi4_write_nd.v
SOURCES  += $(TOP_DIR)/rtl/bus/jelly_axi4_write.v
SOURCES  += $(TOP_DIR)/rtl/bus/jelly_axi4_write_width_convert.v
SOURCES  += $(TOP_DIR)/rtl/dma/jelly_buffer_allocator.v
SOURCES  += $(TOP_DIR)/rtl/dma/jelly_buffer_manager.v
SOURCES  += $(TOP_DIR)/rtl/dma/jelly_dma_stream_read.v
SOURCES  += $(TOP_DIR)/rtl/dma/jelly_dma_stream_write.v
SOURCES  += $(TOP_DIR)/rtl/dma/jelly_dma_video_read.v
SOURCES  += $(TOP_DIR)/rtl/dma/jelly_dma_video_write.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_axi4s_img.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_axi4s_insert_blank.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_axi4s_to_img.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_blk_buffer.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_color_matrix_core.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_color_matrix.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_delay.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_demosaic_acpi_core.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_demosaic_acpi_g_core.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_demosaic_acpi_g_unit.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_demosaic_acpi_rb_core.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_demosaic_acpi_rb_unit.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_demosaic_acpi.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_gamma_correction_core.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_gamma_correction.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_gaussian_3x3_core.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_gaussian_3x3_unit.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_gaussian_3x3.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_line_buffer.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_pixel_buffer.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_selector_core.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_selector.v
SOURCES  += $(TOP_DIR)/rtl/image/jelly_img_to_axi4s.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_address_align_split.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_address_generator_nd.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_address_generator.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_address_width_convert.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_buffer_arbiter.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_capacity_async.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_capacity_buffer.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_capacity_size.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_data_async.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_data_delay.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_data_ff_pack.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_data_ff.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_data_shift_register_lut.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_data_split_pack2.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_data_split_pack.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_data_width_converter.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_demultiplexer.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_fifo_async_fwtf.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_fifo_async.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_fifo_fwtf.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_fifo_generic_fwtf.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_fifo_pack.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_fifo_ram.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_fifo_read_fwtf.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_fifo_shifter.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_fifo.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_func_binary_to_graycode.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_func_graycode_to_binary.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_func_pack.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_func_unpack.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_multiplexer.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_param_update_master.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_param_update_slave.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_pipeline_control.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_pipeline_insert_ff.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_ram_simple_dualport.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_ram_singleport.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_signal_transfer_async.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_signal_transfer_sync.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_signal_transfer.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_stream_add_syncflag.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_stream_gate.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_stream_width_convert_pack.v
SOURCES  += $(TOP_DIR)/rtl/library/jelly_stream_width_convert.v
SOURCES  += $(TOP_DIR)/rtl/math/jelly_fixed_matrix3x4.v
SOURCES  += $(TOP_DIR)/rtl/primitive/jelly_mul_add3.v
SOURCES  += $(TOP_DIR)/rtl/primitive/jelly_mul_add_dsp48e1.v
SOURCES  += $(TOP_DIR)/rtl/video/jelly_mipi_csi2_rx_low_layer.v
SOURCES  += $(TOP_DIR)/rtl/video/jelly_mipi_csi2_rx_raw10.v
SOURCES  += $(TOP_DIR)/rtl/video/jelly_mipi_csi2_rx.v
SOURCES  += $(TOP_DIR)/rtl/video/jelly_mipi_ecc24.v
SOURCES  += $(TOP_DIR)/rtl/video/jelly_mipi_rx_lane_recv.v
SOURCES  += $(TOP_DIR)/rtl/video/jelly_mipi_rx_lane_sync.v
SOURCES  += $(TOP_DIR)/rtl/video/jelly_mipi_rx_lane.v
SOURCES  += $(TOP_DIR)/rtl/video/jelly_video_format_regularizer_core.v
SOURCES  += $(TOP_DIR)/rtl/video/jelly_video_format_regularizer.v
SOURCES  += $(TOP_DIR)/rtl/video/jelly_vout_axi4s.v
SOURCES  += $(TOP_DIR)/rtl/video/jelly_vsync_adjust_de_core.v
SOURCES  += $(TOP_DIR)/rtl/video/jelly_vsync_adjust_de.v
SOURCES  += $(TOP_DIR)/rtl/video/jelly_vsync_generator_core.v
SOURCES  += $(TOP_DIR)/rtl/video/jelly_vsync_generator.v
export SOURCES

# IP cores
IP_CORES  = $(PRJ_DIR)/ip/vivado$(VIVADO_VERSION)/mipi_dphy_cam/mipi_dphy_cam.xci
export IP_CORES

# block design
BD_SCRIPTS = ../vivado$(VIVADO_VERSION)/design_1.tcl
export BD_SCRIPTS

# constrains
CONSTRAINS  = $(PRJ_DIR)/constrain/xdc/top.xdc
CONSTRAINS += $(PRJ_DIR)/constrain/xdc/debug.xdc
export CONSTRAINS

# rules
.PHONY : all
all: clean create build

.PHONY : create
create: $(PRJ_NAME).xpr

$(PRJ_NAME).xpr: $(HLS_EXPORT_FILE)
	vivado -m64 -mode batch -source $(TOP_DIR)/scripts/vivado_create_project.tcl

$(HLS_EXPORT_FILE): build_hls

.PHONY : build
build:
	vivado -m64 -mode batch -source $(TOP_DIR)/scripts/vivado_implementation.tcl

.PHONY : clean
clean:
	-rm -fr .Xil
	-rm -fr $(PRJ_NAME).cache
	-rm -fr $(PRJ_NAME).hw
	-rm -fr $(PRJ_NAME).ip_user_files
	-rm -fr $(PRJ_NAME).runs
	-rm -fr $(PRJ_NAME).sim
	-rm -fr $(PRJ_NAME).srcs
	-rm -fr $(PRJ_NAME).gen
	-rm -fr $(PRJ_NAME).xpr
	-rm -f vivado*.jou
	-rm -f vivado*.log


.PHONY : build_hls
build_hls:
	make -C $(PRJ_DIR)/hls

.PHONY : clean_hls
clean_hls:
	make -C $(PRJ_DIR)/hls clean

.PHONY : distclean
distclean: clean_hls clean
