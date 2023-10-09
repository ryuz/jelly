


DEVICE_NAME = GW1NR-LV9QN88PC6/I5
DEVICE_VERSION = C

BASE_NAME = tang_nano_9k_blinking_led

FS_FILE = impl/pnr/tang_nano_9k_blinking_led.fs

TOP_DIR = ../../../..
RTL_DIR = ../rtl
CTS_DIR = ../cst

VLOG_SOURCES = $(RTL_DIR)/tang_nano_9k_blinking_led.sv

CST_SOURCES = $(CTS_DIR)/tang_nano_9k_blinking_led.cst

# for tcl script
export DEVICE_NAME
export DEVICE_VERSION
export BASE_NAME
export VLOG_SOURCES
export CST_SOURCES
export WSLENV=DEVICE_NAME:DEVICE_VERSION:BASE_NAME:VLOG_SOURCES/l:CST_SOURCES/l

all: $(FS_FILE)

$(FS_FILE): $(VLOG_SOURCES)
	gw_sh $(TOP_DIR)/scripts/gowin_build.tcl

clean:
	rm -fr impl

run: $(FS_FILE)
	openFPGALoader $(FS_FILE)

run2:
	programmer_cli --device GW1NR-9C --run 2 --fsFile $(TARGET).fs --location `programmer_cli --scan-cable | grep -oP 'USB location:\K\d+'`
