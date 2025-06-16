
DEVICE_NAME = GW5AST-LV138FPG676AES

TOP_MODULE = tang_mega_138k_pro_imx219_720p
OUTPUT_BASE_NAME = $(TOP_MODULE)

FS_FILE = impl/pnr/$(OUTPUT_BASE_NAME).fs

TOP_DIR = ../../../..
RTL_DIR = ../rtl
IP_DIR  = ../ip

# include
JELLY_TOP_DIR = $(TOP_DIR)
-include $(JELLY_TOP_DIR)/include/make/def_sources.inc

CONSTRAIN_DIR = ../constrain

VLOG_SOURCES  = $(RTL_DIR)/tang_mega_138k_pro_imx219_720p.sv
VLOG_SOURCES += $(RTL_DIR)/jfive_simple_controller.sv
VLOG_SOURCES += $(RTL_DIR)/dvi_tx.sv
VLOG_SOURCES += $(RTL_DIR)/video_raw_to_rgb.sv
VLOG_SOURCES += $(IP_DIR)/gowin_pll/gowin_pll.v
VLOG_SOURCES += $(IP_DIR)/gowin_pll_mipi/gowin_pll_mipi.v
VLOG_SOURCES += $(IP_DIR)/gowin_pll_dvi/gowin_pll_dvi.v
VLOG_SOURCES += $(IP_DIR)/gowin_pll_ddr3/gowin_pll_ddr3.v
VLOG_SOURCES += $(IP_DIR)/gowin_mipi_dphy_rx/gowin_mipi_dphy_rx.v
VLOG_SOURCES += $(IP_DIR)/mipi_dsi_csi2_rx/mipi_dsi_csi2_rx.v
VLOG_SOURCES += $(IP_DIR)/mipi_byte_to_pixel_converter/mipi_byte_to_pixel_converter.v
VLOG_SOURCES += $(IP_DIR)/ddr3_memory_interface/DDR3_400.v
VLOG_SOURCES += $(IP_DIR)/video_frame_buffer/Video_Frame_Buffer_Top.v
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/jfive/jelly2_jfive_simple_core.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/jfive/jelly2_register_file.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/jfive/jelly2_register_file_ram.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/jfive/jelly2_register_file_ram32x1d.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/primitive/jelly2_ram32x1d.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/peripheral/jelly2_uart.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/peripheral/jelly2_uart_core.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/peripheral/jelly2_uart_rx.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/peripheral/jelly2_uart_tx.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/library/jelly2_fifo_generic_fwtf.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/library/jelly2_fifo_fwtf.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/library/jelly2_fifo.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/library/jelly2_fifo_ram.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/library/jelly2_fifo_read_fwtf.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/library/jelly2_ram_simple_dualport.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/library/jelly2_ram_dualport.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_pipeline_insert_ff.v
VLOG_SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_pipeline_control.v
VLOG_SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_reset.v
VLOG_SOURCES += $(TOP_DIR)/rtl/v1/peripheral/jelly_i2c.v
VLOG_SOURCES += $(TOP_DIR)/rtl/v1/peripheral/jelly_i2c_core.v
VLOG_SOURCES += $(TOP_DIR)/rtl/v1/video/jelly_vsync_generator_core.v
VLOG_SOURCES += $(TOP_DIR)/rtl/v1/video/jelly_dvi_tx_encode.v

VLOG_SOURCES += $(TOP_DIR)/rtl/v3/bus/jelly3_axi4s_if.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/bus/jelly3_axi4l_if.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/bus/jelly3_axi4l_addr_decoder.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/library/jelly3_histry_buffer_mem.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/library/jelly3_histry_buffer_mem_sdp.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/library/jelly3_ram_simple_dualport.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/library/jelly3_stream_delay.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/library/jelly3_data_delay.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/library/jelly3_skid_buffer.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/primitive/jelly3_shift_register.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_axi4s_mat.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_axi4s_to_mat.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_mat_to_axi4s.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_bayer_black_level_calc.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_bayer_black_level_core.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_bayer_black_level.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_bayer_gaussian_calc.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_bayer_gaussian_core.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_bayer_gaussian.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_bayer_lk_sobel.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_bayer_lk.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_bayer_white_balance_core.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_bayer_white_balance.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_demosaic_acpi_core.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_demosaic_acpi_g_calc.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_demosaic_acpi_g_core.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_demosaic_acpi_rb_calc.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_demosaic_acpi_rb_core.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_demosaic_acpi.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_selector_core.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_img_selector.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_mat_buf_blk.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_mat_buf_col.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_mat_buf_mem.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_mat_buf_row.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_mat_clamp_core.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_mat_delay.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/image/jelly3_mat_if.sv

VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_axi4s_img.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_axi4s_img_simple.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_axi4s_to_img_simple.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_img_to_axi4s.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_param_update_master.v
VLOG_SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_param_update_slave.v

VLOG_SOURCES += $(TOP_DIR)/rtl/v3/bus/jelly3_axi4s_fifo.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/bus/jelly2_axi4s_fifo.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/library/jelly2_fifo_pack.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/library/jelly2_func_pack.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v2/library/jelly2_func_unpack.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/video/jelly3_video_format_regularizer_core.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/library/jelly3_stream_ff.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v3/misc/jelly3_axi4s_debug_monitor.sv


#VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_axi4s_img.sv
#VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_axi4s_img_simple.sv
#VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_axi4s_to_img_simple.sv
#VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_img_to_axi4s.sv
#VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_img_blk_buffer.sv
#VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_img_pixel_buffer.sv
#VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_img_line_buffer.sv
#VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_img_demosaic_acpi_core.sv
#VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_img_demosaic_acpi_g_core.sv
#VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_img_demosaic_acpi_rb_core.sv
#VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_img_demosaic_acpi.sv
#VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_img_color_matrix_core.sv
#VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_img_color_matrix.sv
#VLOG_SOURCES += $(TOP_DIR)/rtl/v2/image/jelly2_img_delay.sv
#VLOG_SOURCES += $(TOP_DIR)/rtl/v2/library/jelly2_ram_singleport.sv
#VLOG_SOURCES += $(TOP_DIR)/rtl/v1/image/jelly_img_demosaic_acpi_rb_calc.v
#VLOG_SOURCES += $(TOP_DIR)/rtl/v1/image/jelly_img_demosaic_acpi_g_calc.v
#VLOG_SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_param_update_master.v
#VLOG_SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_param_update_slave.v
#VLOG_SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_data_delay.v
#VLOG_SOURCES += $(TOP_DIR)/rtl/v1/math/jelly_fixed_matrix3x4.v
#VLOG_SOURCES += $(TOP_DIR)/rtl/v1/primitive/jelly_mul_add3.v


#VLOG_SOURCES += $(JELLY_RTL_SOURCES)

VG_SOURCES    = ./jfive_tcm/impl/gwsynthesis/jfive_tcm.vg
VLOG_SOURCES += $(VG_SOURCES)

SDC_SOURCES  = $(CONSTRAIN_DIR)/tang_mega_138k_pro_imx219.sdc
CST_SOURCES  = $(CONSTRAIN_DIR)/tang_mega_138k_pro_imx219.cst

export USE_CPU_AS_GPIO = 1

# for tcl script
export DEVICE_NAME
export DEVICE_VERSION
export TOP_MODULE
export OUTPUT_BASE_NAME
export VLOG_SOURCES
export SDC_SOURCES
export CST_SOURCES
export WSLENV=DEVICE_NAME:DEVICE_VERSION:TOP_MODULE:OUTPUT_BASE_NAME:VLOG_SOURCES:SDC_SOURCES:CST_SOURCES:USE_CPU_AS_GPIO

.PHONY: all
all: $(FS_FILE)

.PHONY: jfive
jfive:
	make -C ./jfive_tcm all

$(VG_SOURCES):
	make -C ./jfive_tcm all

$(FS_FILE): $(VLOG_SOURCES) $(CST_SOURCES) $(VG_SOURCES)
	gw_sh $(TOP_DIR)/scripts/gowin_build.tcl

clean:
	rm -fr impl
	make -C ./jfive_tcm clean

run: $(FS_FILE)
	openFPGALoader $(FS_FILE)

run_wsl: $(FS_FILE)
#   programmer_cli --scan-cable
	programmer_cli --device GW5AST-138C --run 2 --fsFile '$(shell wslpath -w $(FS_FILE))' --location 11585
