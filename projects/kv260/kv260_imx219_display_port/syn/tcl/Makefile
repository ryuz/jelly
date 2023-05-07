

# get vivado version
empty:=
space:= $(empty) $(empty)
VIVADO_VERSIONS := $(subst .,$(space),$(subst v,,$(word 2,$(shell vivado -version))))
VIVADO_VERSION  := $(word 1,$(VIVADO_VERSIONS)).$(word 2,$(VIVADO_VERSIONS))

# settings
export PRJ_NAME    = kv260_imx219_display_port_tcl
export TOP_MODULE  = kv260_imx219_display_port
export BOARD_PART  = xilinx.com:kv260_som*
export DEVICE_PART =

# directories
TOP_DIR = ../../../../..

PRJ_DIR = ../..

# include
JELLY_TOP_DIR = $(TOP_DIR)
-include $(JELLY_TOP_DIR)/include/make/def_sources.inc

# HLS IP
HLS_IP =
export HLS_IP

# sources
SOURCES  = $(PRJ_DIR)/rtl/kv260_imx219_display_port.sv
SOURCES += $(PRJ_DIR)/rtl/image_processing.sv
SOURCES += $(JELLY_RTL_SOURCES)
export SOURCES

# IP cores
IP_CORES  = ../../ip/vivado$(VIVADO_VERSION)/mipi_dphy_cam/mipi_dphy_cam.xci
export IP_CORES

# block design
BD_SCRIPTS = ../vivado$(VIVADO_VERSION)/design_1.tcl
export BD_SCRIPTS

# constrains
CONSTRAINS  = ../../constrain/top.xdc
CONSTRAINS += ../../constrain/debug.xdc
export CONSTRAINS


# rules
.PHONY : all
all: build

.PHONY : rebuild
rebuild: clean create build

.PHONY : create
create: $(PRJ_NAME).xpr

$(PRJ_NAME).xpr: $(SOURCES) $(IP_CORES) $(CONSTRAINS)
	vivado -m64 -mode batch -source $(TOP_DIR)/scripts/vivado_create_project.tcl

.PHONY : build
build:
	vivado -m64 -mode batch -source $(TOP_DIR)/scripts/vivado_implementation.tcl

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
