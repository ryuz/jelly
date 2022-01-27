

# get vivado version
empty:=
space:= $(empty) $(empty)
VIVADO_VERSIONS := $(subst .,$(space),$(subst v,,$(word 2,$(shell vivado -version))))
VIVADO_VERSION  := $(word 1,$(VIVADO_VERSIONS)).$(word 2,$(VIVADO_VERSIONS))


# settings
export PRJ_NAME    = ultra96v2_imx219_display_port_tcl
export TOP_MODULE  = ultra96v2_imx219_display_port
export BOARD_PART  = avnet.com:ultra96v2*
export DEVICE_PART = xczu3eg-sbva484-1-i


# sources
SOURCES  = ../../rtl/image_processing.v
SOURCES += ../../rtl/ultra96v2_imx219_display_port.v
SOURCES += ../../../../rtl/bus/jelly_axi4l_to_wishbone.v
SOURCES += ../../../../rtl/bus/jelly_axi4_read_nd.v
SOURCES += ../../../../rtl/bus/jelly_axi4_read.v
SOURCES += ../../../../rtl/bus/jelly_axi4_read_width_convert.v
SOURCES += ../../../../rtl/bus/jelly_axi4s_fifo.v
SOURCES += ../../../../rtl/bus/jelly_axi4s_fifo_width_convert.v
SOURCES += ../../../../rtl/bus/jelly_axi4s_width_convert.v
SOURCES += ../../../../rtl/bus/jelly_axi4_write_nd.v
SOURCES += ../../../../rtl/bus/jelly_axi4_write.v
SOURCES += ../../../../rtl/bus/jelly_axi4_write_width_convert.v
SOURCES += ../../../../rtl/dma/jelly_buffer_allocator.v
SOURCES += ../../../../rtl/dma/jelly_buffer_manager.v
SOURCES += ../../../../rtl/dma/jelly_dma_fifo_core.v
SOURCES += ../../../../rtl/dma/jelly_dma_fifo_read.v
SOURCES += ../../../../rtl/dma/jelly_dma_fifo_write.v
SOURCES += ../../../../rtl/dma/jelly_dma_stream_read.v
SOURCES += ../../../../rtl/dma/jelly_dma_stream_write.v
SOURCES += ../../../../rtl/dma/jelly_dma_video_read.v
SOURCES += ../../../../rtl/dma/jelly_dma_video_write.v
SOURCES += ../../../../rtl/image/jelly_axi4s_img.v
SOURCES += ../../../../rtl/image/jelly_axi4s_insert_blank.v
SOURCES += ../../../../rtl/image/jelly_axi4s_to_img.v
SOURCES += ../../../../rtl/image/jelly_img_absdiff.v
SOURCES += ../../../../rtl/image/jelly_img_binarizer_core.v
SOURCES += ../../../../rtl/image/jelly_img_binarizer.v
SOURCES += ../../../../rtl/image/jelly_img_blk_buffer.v
SOURCES += ../../../../rtl/image/jelly_img_canny_core.v
SOURCES += ../../../../rtl/image/jelly_img_canny.v
SOURCES += ../../../../rtl/image/jelly_img_colormap_core.v
SOURCES += ../../../../rtl/image/jelly_img_color_matrix_core.v
SOURCES += ../../../../rtl/image/jelly_img_color_matrix.v
SOURCES += ../../../../rtl/image/jelly_img_delay.v
SOURCES += ../../../../rtl/image/jelly_img_demosaic_acpi_core.v
SOURCES += ../../../../rtl/image/jelly_img_demosaic_acpi_g_core.v
SOURCES += ../../../../rtl/image/jelly_img_demosaic_acpi_g_unit.v
SOURCES += ../../../../rtl/image/jelly_img_demosaic_acpi_rb_core.v
SOURCES += ../../../../rtl/image/jelly_img_demosaic_acpi_rb_unit.v
SOURCES += ../../../../rtl/image/jelly_img_demosaic_acpi.v
SOURCES += ../../../../rtl/image/jelly_img_gamma_correction_core.v
SOURCES += ../../../../rtl/image/jelly_img_gamma_correction.v
SOURCES += ../../../../rtl/image/jelly_img_gaussian_3x3_core.v
SOURCES += ../../../../rtl/image/jelly_img_gaussian_3x3_unit.v
SOURCES += ../../../../rtl/image/jelly_img_gaussian_3x3.v
SOURCES += ../../../../rtl/image/jelly_img_line_buffer.v
SOURCES += ../../../../rtl/image/jelly_img_pixel_buffer.v
SOURCES += ../../../../rtl/image/jelly_img_previous_frame_core.v
SOURCES += ../../../../rtl/image/jelly_img_previous_frame.v
SOURCES += ../../../../rtl/image/jelly_img_rgb_to_gray.v
SOURCES += ../../../../rtl/image/jelly_img_selector_core.v
SOURCES += ../../../../rtl/image/jelly_img_selector.v
SOURCES += ../../../../rtl/image/jelly_img_sobel_core.v
SOURCES += ../../../../rtl/image/jelly_img_sobel_unit.v
SOURCES += ../../../../rtl/image/jelly_img_to_axi4s.v
SOURCES += ../../../../rtl/library/jelly_address_align_split.v
SOURCES += ../../../../rtl/library/jelly_address_generator_nd.v
SOURCES += ../../../../rtl/library/jelly_address_generator_range.v
SOURCES += ../../../../rtl/library/jelly_address_generator.v
SOURCES += ../../../../rtl/library/jelly_address_offset.v
SOURCES += ../../../../rtl/library/jelly_address_width_convert.v
SOURCES += ../../../../rtl/library/jelly_buffer_arbiter.v
SOURCES += ../../../../rtl/library/jelly_busy_control.v
SOURCES += ../../../../rtl/library/jelly_capacity_async.v
SOURCES += ../../../../rtl/library/jelly_capacity_buffer.v
SOURCES += ../../../../rtl/library/jelly_capacity_control.v
SOURCES += ../../../../rtl/library/jelly_capacity_size.v
SOURCES += ../../../../rtl/library/jelly_capacity_timeout.v
SOURCES += ../../../../rtl/library/jelly_colormap_table.v
SOURCES += ../../../../rtl/library/jelly_colormap.v
SOURCES += ../../../../rtl/library/jelly_data_async.v
SOURCES += ../../../../rtl/library/jelly_data_delay.v
SOURCES += ../../../../rtl/library/jelly_data_ff_pack.v
SOURCES += ../../../../rtl/library/jelly_data_ff.v
SOURCES += ../../../../rtl/library/jelly_data_shift_register_lut.v
SOURCES += ../../../../rtl/library/jelly_data_split_pack2.v
SOURCES += ../../../../rtl/library/jelly_data_split_pack.v
SOURCES += ../../../../rtl/library/jelly_data_width_converter.v
SOURCES += ../../../../rtl/library/jelly_demultiplexer.v
SOURCES += ../../../../rtl/library/jelly_fifo_async_fwtf.v
SOURCES += ../../../../rtl/library/jelly_fifo_async.v
SOURCES += ../../../../rtl/library/jelly_fifo_fwtf.v
SOURCES += ../../../../rtl/library/jelly_fifo_generic_fwtf.v
SOURCES += ../../../../rtl/library/jelly_fifo_pack.v
SOURCES += ../../../../rtl/library/jelly_fifo_ram.v
SOURCES += ../../../../rtl/library/jelly_fifo_read_fwtf.v
SOURCES += ../../../../rtl/library/jelly_fifo_shifter.v
SOURCES += ../../../../rtl/library/jelly_fifo.v
SOURCES += ../../../../rtl/library/jelly_fifo_width_convert_pack.v
SOURCES += ../../../../rtl/library/jelly_fifo_width_convert.v
SOURCES += ../../../../rtl/library/jelly_func_binary_to_graycode.v
SOURCES += ../../../../rtl/library/jelly_func_graycode_to_binary.v
SOURCES += ../../../../rtl/library/jelly_func_pack.v
SOURCES += ../../../../rtl/library/jelly_func_unpack.v
SOURCES += ../../../../rtl/library/jelly_multiplexer.v
SOURCES += ../../../../rtl/library/jelly_param_update_master.v
SOURCES += ../../../../rtl/library/jelly_param_update_slave.v
SOURCES += ../../../../rtl/library/jelly_pipeline_control.v
SOURCES += ../../../../rtl/library/jelly_pipeline_insert_ff.v
SOURCES += ../../../../rtl/library/jelly_ram_simple_dualport.v
SOURCES += ../../../../rtl/library/jelly_ram_singleport.v
SOURCES += ../../../../rtl/library/jelly_signal_transfer_async.v
SOURCES += ../../../../rtl/library/jelly_signal_transfer_sync.v
SOURCES += ../../../../rtl/library/jelly_signal_transfer.v
SOURCES += ../../../../rtl/library/jelly_stream_add_syncflag.v
SOURCES += ../../../../rtl/library/jelly_stream_gate.v
SOURCES += ../../../../rtl/library/jelly_stream_width_convert_pack.v
SOURCES += ../../../../rtl/library/jelly_stream_width_convert.v
SOURCES += ../../../../rtl/math/jelly_fixed_atan2.v
SOURCES += ../../../../rtl/math/jelly_fixed_matrix3x4.v
SOURCES += ../../../../rtl/primitive/jelly_mul_add3.v
SOURCES += ../../../../rtl/primitive/jelly_mul_add_dsp48e1.v
SOURCES += ../../../../rtl/video/jelly_mipi_csi2_rx_low_layer.v
SOURCES += ../../../../rtl/video/jelly_mipi_csi2_rx_raw10.v
SOURCES += ../../../../rtl/video/jelly_mipi_csi2_rx.v
SOURCES += ../../../../rtl/video/jelly_mipi_ecc24.v
SOURCES += ../../../../rtl/video/jelly_mipi_rx_lane_recv.v
SOURCES += ../../../../rtl/video/jelly_mipi_rx_lane_sync.v
SOURCES += ../../../../rtl/video/jelly_mipi_rx_lane.v
SOURCES += ../../../../rtl/video/jelly_video_format_regularizer_core.v
SOURCES += ../../../../rtl/video/jelly_video_format_regularizer.v
SOURCES += ../../../../rtl/video/jelly_vout_axi4s.v
SOURCES += ../../../../rtl/video/jelly_vsync_adjust_de_core.v
SOURCES += ../../../../rtl/video/jelly_vsync_adjust_de.v
SOURCES += ../../../../rtl/video/jelly_vsync_generator_core.v
SOURCES += ../../../../rtl/video/jelly_vsync_generator.v
export SOURCES

# IP cores
IP_CORES  = ../../ip/vivado$(VIVADO_VERSION)/mipi_dphy_cam/mipi_dphy_cam.xci
export IP_CORES

# block design
BD_SCRIPTS = ../vivado$(VIVADO_VERSION)/design_1.tcl
export BD_SCRIPTS

# constrains
CONSTRAINS += ../../constrain/xdc/debug.xdc
CONSTRAINS +=../../constrain/xdc/top.xdc
export CONSTRAINS


# rules

.PHONY : all
all: clean create build

.PHONY : create
create: $(PRJ_NAME).xpr

$(PRJ_NAME).xpr:
	vivado -m64 -mode batch -source create_project.tcl

.PHONY : build
build:
	vivado -m64 -mode batch -source implementation.tcl

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


.PHONY: build_hls_if
build_hls_if:
	@if [ ! -e $(HLS_EXPORT_FILE) ]; then \
		make -C ../../hls ; \
	fi \

.PHONY : build_hls
build_hls:
	make -C ../../hls

.PHONY : clean_hls
clean_hls:
	make -C ../../hls clean

.PHONY : distclean
distclean: clean_hls clean
