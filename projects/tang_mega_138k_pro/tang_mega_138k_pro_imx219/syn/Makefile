#DEVICE_NAME = GW1NSR-LV4CQN48PC6/I5
#DEVICE_NAME = GW1NSR-LV4CQN48PC6/I5
#DEVICE_NAME = GW1NR-LV9QN88PC6/I5
DEVICE_NAME = GW5AST-LV138FPG676AES

TOP_MODULE = tang_mega_138k_pro_imx219
OUTPUT_BASE_NAME = $(TOP_MODULE)

FS_FILE = impl/pnr/$(OUTPUT_BASE_NAME).fs

TOP_DIR = ../../../..
RTL_DIR = ../rtl
IP_DIR  = ../ip

# include
JELLY_TOP_DIR = $(TOP_DIR)
-include $(JELLY_TOP_DIR)/include/make/def_sources.inc

CONSTRAIN_DIR = ../constrain

VLOG_SOURCES  = $(RTL_DIR)/tang_mega_138k_pro_imx219.sv
VLOG_SOURCES += $(RTL_DIR)/jfive_simple_controller.sv
VLOG_SOURCES += $(RTL_DIR)/Gowin_PLL_dvi.v
VLOG_SOURCES += $(RTL_DIR)/clkgen_clkdiv.sv
VLOG_SOURCES += $(RTL_DIR)/dvi_tx.sv
#VLOG_SOURCES += $(RTL_DIR)/draw_video.sv
VLOG_SOURCES += $(IP_DIR)/gowin_pll/gowin_pll.v
VLOG_SOURCES += $(IP_DIR)/gowin_mipi_dphy_rx/gowin_mipi_dphy_rx.v
VLOG_SOURCES += $(IP_DIR)/mipi_dsi_csi2_rx/mipi_dsi_csi2_rx.v
VLOG_SOURCES += $(IP_DIR)/mipi_byte_to_pixel_converter/mipi_byte_to_pixel_converter.v
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
#VLOG_SOURCES += $(JELLY_RTL_SOURCES)

VG_SOURCES    = ./jfive_tcm/impl/gwsynthesis/jfive_tcm.vg
VLOG_SOURCES += $(VG_SOURCES)

CST_SOURCES  = $(CONSTRAIN_DIR)/tang_mega_138k_pro_imx219.sdc
CST_SOURCES += $(CONSTRAIN_DIR)/tang_mega_138k_pro_imx219.cst

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
