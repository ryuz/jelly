

# get vivado version
empty:=
space:= $(empty) $(empty)
VIVADO_VERSIONS := $(subst .,$(space),$(subst v,,$(word 2,$(shell vivado -version))))
VIVADO_VERSION  := $(word 1,$(VIVADO_VERSIONS)).$(word 2,$(VIVADO_VERSIONS))

# settings
PROJECT_NAME = kv260_imx219_hls_sample
BOARD_NAME   = kv260
export PRJ_NAME     = $(PROJECT_NAME)_tcl
export TOP_MODULE   = $(PROJECT_NAME)
export BOARD_PART   = xilinx.com:kv260_som*
export DEVICE_PART  = 

BOARD_ADDRESS  ?= kria
BOARD_WORK_DIR ?= git-work/jelly

BIT_FILE = $(PRJ_NAME).runs/impl_1/$(TOP_MODULE).bit


# directories
TOP_DIR = ../../../../..

PRJ_DIR = ../..

# include
JELLY_TOP_DIR = $(TOP_DIR)
-include $(JELLY_TOP_DIR)/include/make/def_sources.inc


# HLS
HLS_DIR = $(PRJ_DIR)/hls/gaussian_filter $(PRJ_DIR)/hls/laplacian_filter
HLS_EXPORT_FILE  = $(PRJ_DIR)/hls/gaussian_filter/gaussian_filter/solution_1/impl/export.zip
HLS_EXPORT_FILE += $(PRJ_DIR)/hls/laplacian_filter/laplacian_filter/solution_1/impl/export.zip

# HLS IP
HLS_IP = gaussian_filter,gaussian_filter_0 laplacian_filter,laplacian_filter_0
export HLS_IP
export HLS_DIR

# sources
SOURCES  = $(PRJ_DIR)/rtl/kv260_imx219_hls_sample.sv
SOURCES += $(PRJ_DIR)/rtl/image_processing.sv
SOURCES += $(PRJ_DIR)/rtl/gaussian_filter_hls.sv
SOURCES += $(PRJ_DIR)/rtl/laplacian_filter_hls.sv
SOURCES += $(JELLY_RTL_SOURCES)
export SOURCES


# IP cores
IP_CORES  =  $(PRJ_DIR)/ip/vivado$(VIVADO_VERSION)/mipi_dphy_cam/mipi_dphy_cam.xci
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

.PHONY : build
build: build_hls $(BIT_FILE) check_log

.PHONY : bit_scp
bit_scp: $(BIT_FILE)
	scp $(BIT_FILE) $(BOARD_ADDRESS):$(BOARD_WORK_DIR)/projects/$(BOARD_NAME)/$(PROJECT_NAME)/app

.PHONY : bit_scp_force
bit_scp_force:
	scp $(BIT_FILE) $(BOARD_ADDRESS):$(BOARD_WORK_DIR)/projects/$(BOARD_NAME)/$(PROJECT_NAME)/app

.PHONY : bit_cp
bit_cp: $(BIT_FILE)
	cp $(BIT_FILE) ../../app

.PHONY : bit_cp_force
bit_cp_force: $(BIT_FILE)
	cp $(BIT_FILE) ../../app

$(PRJ_NAME).xpr: $(SOURCES) $(CONSTRAINS) $(IP_CORES) $(BD_SCRIPTS) Makefile
	rm -f $(PRJ_NAME).xpr
	vivado -m64 -mode batch -source $(TOP_DIR)/scripts/vivado_create_project.tcl

$(BIT_FILE): $(PRJ_NAME).xpr
	vivado -m64 -mode batch -source $(TOP_DIR)/scripts/vivado_implementation.tcl

.PHONY : check_log
check_log:
	@echo "----- synth_1 -----"
	@cat $(PRJ_NAME).runs/synth_1/runme.log | grep encountered.
	@echo "----- impl_1 -----"
	@cat $(PRJ_NAME).runs/impl_1/runme.log | grep encountered.

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


.PHONY : build_hls
build_hls:
	make -C $(PRJ_DIR)/hls/gaussian_filter
	make -C $(PRJ_DIR)/hls/laplacian_filter

.PHONY : clean_hls
clean_hls:
	make -C $(PRJ_DIR)/hls/gaussian_filter  clean
	make -C $(PRJ_DIR)/hls/laplacian_filter clean

.PHONY : distclean
distclean: clean_hls clean
