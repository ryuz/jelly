


DEVICE_NAME = GW1NR-LV9QN88PC6/I5
DEVICE_VERSION = C

TOP_MODULE = tang_nano_9k_blinking_led
OUTPUT_BASE_NAME = $(TOP_MODULE)

FS_FILE = impl/pnr/$(OUTPUT_BASE_NAME).fs

TOP_DIR = ../../../..
RTL_DIR = ../rtl
CONSTRAIN_DIR = ../constrain

VLOG_SOURCES = $(RTL_DIR)/tang_nano_9k_blinking_led.sv

CST_SOURCES = $(CONSTRAIN_DIR)/tang_nano_9k_blinking_led.sdc
CST_SOURCES = $(CONSTRAIN_DIR)/tang_nano_9k_blinking_led.cst

# for tcl script
export DEVICE_NAME
export DEVICE_VERSION
export TOP_MODULE
export OUTPUT_BASE_NAME
export VLOG_SOURCES
export SDC_SOURCES
export CST_SOURCES
export WSLENV=DEVICE_NAME:DEVICE_VERSION:TOP_MODULE:OUTPUT_BASE_NAME:VLOG_SOURCES:SDC_SOURCES:CST_SOURCES

all: $(FS_FILE)

$(FS_FILE): $(VLOG_SOURCES) $(CST_SOURCES)
	gw_sh $(TOP_DIR)/scripts/gowin_build.tcl

clean:
	rm -fr impl

run: $(FS_FILE)
	openFPGALoader $(FS_FILE)

run2:
	programmer_cli --device GW1NR-9C --run 2 --fsFile $(TARGET).fs --location `programmer_cli --scan-cable | grep -oP 'USB location:\K\d+'`
