


#DEVICE_NAME = GW1NSR-LV4CQN48PC6/I5
DEVICE_NAME = GW1NSR-LV4CQN48PC6/I5
#DEVICE_NAME = GW1NR-LV9QN88PC6/I5
DEVICE_VERSION = 

TOP_MODULE = tang_nano_4k_mnist
OUTPUT_BASE_NAME = $(TOP_MODULE)

FS_FILE = impl/pnr/$(OUTPUT_BASE_NAME).fs

TOP_DIR = ../../../..
RTL_DIR = ../rtl
EXSAMPLE_DIR = ../TangNano-4K-example/camera_hdmi/src
CONSTRAIN_DIR = ../constrain

VLOG_SOURCES  = $(RTL_DIR)/tang_nano_4k_mnist.sv
VLOG_SOURCES += $(RTL_DIR)/frame_buffer.sv
VLOG_SOURCES += $(RTL_DIR)/MnistLut4Simple.v
VLOG_SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_reset.v
#VLOG_SOURCES += $(EXSAMPLE_DIR)/video_top.v
VLOG_SOURCES += $(EXSAMPLE_DIR)/gowin_pllvr/GW_PLLVR.v
VLOG_SOURCES += $(EXSAMPLE_DIR)/gowin_pllvr/TMDS_PLLVR.v
VLOG_SOURCES += $(EXSAMPLE_DIR)/ov2640/I2C_Interface.v
VLOG_SOURCES += $(EXSAMPLE_DIR)/ov2640/OV2640_Controller.v
VLOG_SOURCES += $(EXSAMPLE_DIR)/ov2640/OV2640_Registers.v

VLOG_SOURCES += $(EXSAMPLE_DIR)/hyperram_memory_interface/hyperram_memory_interface.v
VLOG_SOURCES += $(EXSAMPLE_DIR)/video_frame_buffer/video_frame_buffer.v

VLOG_SOURCES += $(EXSAMPLE_DIR)/dvi_tx/dvi_tx.v
VLOG_SOURCES += $(EXSAMPLE_DIR)/syn_code/syn_gen.v

CST_SOURCES  = $(CONSTRAIN_DIR)/tang_nano_4k_mnist.sdc
CST_SOURCES += $(CONSTRAIN_DIR)/tang_nano_4k_mnist.cst

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
	programmer_cli --device GW1NSR-4C --run 2 --fsFile $(TARGET).fs --location `programmer_cli --scan-cable | grep -oP 'USB location:\K\d+'`
