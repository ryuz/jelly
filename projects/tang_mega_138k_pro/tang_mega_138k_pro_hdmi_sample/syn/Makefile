

DEVICE_NAME = GW5AST-LV138FPG676AES

TOP_MODULE = tang_mega_138k_pro_hdmi_sample
OUTPUT_BASE_NAME = $(TOP_MODULE)

FS_FILE = impl/pnr/$(OUTPUT_BASE_NAME).fs

TOP_DIR = ../../../..
RTL_DIR = ../rtl
CONSTRAIN_DIR = ../constrain

VLOG_SOURCES  = $(RTL_DIR)/tang_mega_138k_pro_hdmi_sample.sv
VLOG_SOURCES += $(RTL_DIR)/Gowin_PLL.v
VLOG_SOURCES += $(RTL_DIR)/clkgen_clkdiv.sv
VLOG_SOURCES += $(RTL_DIR)/dvi_tx.sv
VLOG_SOURCES += $(RTL_DIR)/draw_video.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_reset.v
VLOG_SOURCES += $(TOP_DIR)/rtl/v1/video/jelly_dvi_tx_encode.v
VLOG_SOURCES += $(TOP_DIR)/rtl/v1/video/jelly_vsync_generator_core.v

SDC_SOURCES  = $(CONSTRAIN_DIR)/tang_mega_138k_pro_hdmi_sample.sdc
CST_SOURCES += $(CONSTRAIN_DIR)/tang_mega_138k_pro_hdmi_sample.cst

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

all: $(FS_FILE)

$(FS_FILE): $(VLOG_SOURCES) $(CST_SOURCES)
	gw_sh $(TOP_DIR)/scripts/gowin_build.tcl

clean:
	rm -fr impl

run: $(FS_FILE)
	openFPGALoader $(FS_FILE)

run2:
	programmer_cli --device GW1NR-9C --run 2 --fsFile $(TARGET).fs --location `programmer_cli --scan-cable | grep -oP 'USB location:\K\d+'`
