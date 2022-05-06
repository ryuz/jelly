

# get vivado version
empty:=
space:= $(empty) $(empty)
VIVADO_VERSIONS := $(subst .,$(space),$(subst v,,$(word 2,$(shell vivado -version))))
VIVADO_VERSION  := $(word 1,$(VIVADO_VERSIONS)).$(word 2,$(VIVADO_VERSIONS))

# settings
export PRJ_NAME     = ultra96v2_jfive_sample_tcl
export TOP_MODULE   = ultra96v2_jfive_sample
export BOARD_PART   = avnet.com:ultra96v2*
export DEVICE_PART  = xczu3eg-sbva484-1-i

# directories
TOP_DIR = ../../../..
PRJ_DIR = ../..


# HLS IP
HLS_IP =
export HLS_IP

# sources
SOURCES  = $(PRJ_DIR)/rtl/ultra96v2_jfive_sample.sv
SOURCES += $(TOP_DIR)/rtl/jfive/jelly2_jfive_simple_controller.sv
SOURCES += $(TOP_DIR)/rtl/jfive/jelly2_jfive_simple_core.sv
SOURCES += $(TOP_DIR)/rtl/jfive/jelly2_register_file.sv
SOURCES += $(TOP_DIR)/rtl/jfive/jelly2_register_file_ram.sv
SOURCES += $(TOP_DIR)/rtl/jfive/jelly2_register_file_ram32x1d.sv
SOURCES += $(TOP_DIR)/rtl/bus/jelly_axi4l_to_wishbone.v
SOURCES += $(TOP_DIR)/rtl/library/jelly2_ram_dualport.sv
SOURCES += $(TOP_DIR)/rtl/primitive/jelly2_ram32x1d.sv
export SOURCES


# IP cores
IP_CORES  =
export IP_CORES

# block design
BD_SCRIPTS = ../vivado$(VIVADO_VERSION)/design_1.tcl
export BD_SCRIPTS

# constrains
CONSTRAINS +=../../constrain/xdc/top.xdc
CONSTRAINS += ../../constrain/xdc/debug.xdc
export CONSTRAINS


# rules
.PHONY : all
all: clean create build

.PHONY : create
create: $(PRJ_NAME).xpr

$(PRJ_NAME).xpr:
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
