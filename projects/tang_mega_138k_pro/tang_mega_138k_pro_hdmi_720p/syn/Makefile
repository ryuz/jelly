

DEVICE_NAME = GW5AST-LV138FPG676AES

TOP_MODULE = tang_mega_138k_pro_hdmi_720p
OUTPUT_BASE_NAME = $(TOP_MODULE)

FS_FILE = impl/pnr/$(OUTPUT_BASE_NAME).fs

TOP_DIR = ../../../..
RTL_DIR = ../rtl
IP_DIR  = ../ip
CONSTRAIN_DIR = ../constrain

VLOG_SOURCES  = $(RTL_DIR)/tang_mega_138k_pro_hdmi_720p.sv
VLOG_SOURCES += $(RTL_DIR)/dvi_tx.sv
VLOG_SOURCES += $(RTL_DIR)/draw_video.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_reset.v
VLOG_SOURCES += $(TOP_DIR)/rtl/v1/video/jelly_dvi_tx_encode.v
VLOG_SOURCES += $(TOP_DIR)/rtl/v1/video/jelly_vsync_generator_core.v
VLOG_SOURCES += $(IP_DIR)/gowin_pll/gowin_pll.v

SDC_SOURCES  = $(CONSTRAIN_DIR)/tang_mega_138k_pro_hdmi_720p.sdc
CST_SOURCES += $(CONSTRAIN_DIR)/tang_mega_138k_pro_hdmi_720p.cst

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

.PONONY: all
all: $(FS_FILE)

$(FS_FILE): $(VLOG_SOURCES) $(CST_SOURCES)
	gw_sh $(TOP_DIR)/scripts/gowin_build.tcl

.PHONY: clean
clean:
	rm -fr impl

.PHONY: run
run: $(FS_FILE)
	openFPGALoader $(FS_FILE)

.PHONY: run2
run_lin:
	programmer_cli --device GW1NR-9C --run 2 --fsFile $(TARGET).fs --location `programmer_cli --scan-cable | grep -oP 'USB location:\K\d+'`

run_wsl: $(FS_FILE)
#   programmer_cli --scan-cable
	programmer_cli --device GW5AST-138C --run 2 --fsFile '$(shell wslpath -w $(FS_FILE))' --location 11585
