


DEVICE_NAME = GW1NR-LV9QN88PC6/I5
DEVICE_VERSION = C

BASE_NAME = tang_nano_9k_hdmi_sample

FS_FILE = impl/pnr/$(BASE_NAME).fs

TOP_DIR = ../../../..
RTL_DIR = ../rtl
CTS_DIR = ../cst

VLOG_SOURCES  = $(RTL_DIR)/tang_nano_9k_hdmi_sample.sv
VLOG_SOURCES += $(RTL_DIR)/clkgen_pll.sv
VLOG_SOURCES += $(RTL_DIR)/clkgen_clkdiv.sv
VLOG_SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_reset.v

CST_SOURCES = $(CTS_DIR)/tang_nano_9k_hdmi_sample.cst

# for tcl script
export DEVICE_NAME
export DEVICE_VERSION
export BASE_NAME
export VLOG_SOURCES
export CST_SOURCES
export WSLENV=DEVICE_NAME:DEVICE_VERSION:BASE_NAME:VLOG_SOURCES:CST_SOURCES

all: $(FS_FILE)

$(FS_FILE): $(VLOG_SOURCES)
	gw_sh $(TOP_DIR)/scripts/gowin_build.tcl

clean:
	rm -fr impl

run: $(FS_FILE)
	openFPGALoader $(FS_FILE)

run2:
	programmer_cli --device GW1NR-9C --run 2 --fsFile $(TARGET).fs --location `programmer_cli --scan-cable | grep -oP 'USB location:\K\d+'`
