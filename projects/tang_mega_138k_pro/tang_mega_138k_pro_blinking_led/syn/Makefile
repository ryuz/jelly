
DEVICE_NAME = GW5AST-LV138FPG676AES

TOP_MODULE = tang_mega_138k_pro_blinking_led
OUTPUT_BASE_NAME = $(TOP_MODULE)

FS_FILE = impl/pnr/$(OUTPUT_BASE_NAME).fs

TOP_DIR = ../../../..
RTL_DIR = ../rtl
CONSTRAIN_DIR = ../constrain

VLOG_SOURCES = $(RTL_DIR)/tang_mega_138k_pro_blinking_led.sv

SDC_SOURCES  = $(CONSTRAIN_DIR)/tang_mega_138k_pro_blinking_led.sdc
CST_SOURCES  = $(CONSTRAIN_DIR)/tang_mega_138k_pro_blinking_led.cst

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

# WSL から Windows 版 programmer を使う場合
# programmer_cli --scan-cable
# で PROGRAMMER_CLI_OPTIONS に --location を指定しておく
run_wsl: $(FS_FILE)
	programmer_cli --device GW5AST-138C --run 2 $(PROGRAMMER_CLI_OPTIONS) --fsFile '$(shell wslpath -w $(FS_FILE))'
