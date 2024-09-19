

# get vivado version
empty:=
space:= $(empty) $(empty)
VIVADO_VERSIONS := $(subst .,$(space),$(subst v,,$(word 2,$(shell vivado -version))))
VIVADO_VERSION  := $(word 1,$(VIVADO_VERSIONS)).$(word 2,$(VIVADO_VERSIONS))

# settings
PROJECT_NAME = kv260_sample
BOARD_NAME   = kv260
export PRJ_NAME     = $(PROJECT_NAME)_tcl
export TOP_MODULE   = $(PROJECT_NAME)
export BOARD_PART   = xilinx.com:kv260_som*
export DEVICE_PART  = 

ifdef KV260_BOARD_ADDRESS
BOARD_ADDRESS ?= $(KV260_BOARD_ADDRESS)
else
BOARD_ADDRESS ?= kria
endif

BOARD_WORK_DIR ?= git-work/jelly

BIT_FILE = $(PRJ_NAME).runs/impl_1/$(TOP_MODULE).bit


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
SOURCES  = $(PRJ_DIR)/rtl/kv260_sample.sv
export SOURCES

# IP cores
IP_CORES  =
export IP_CORES

# block design
BD_SCRIPTS = ../vivado$(VIVADO_VERSION)/design_1.tcl
export BD_SCRIPTS

# constrains
CONSTRAINS  = ../../constrain/top.xdc
#CONSTRAINS += ../../constrain/debug.xdc
export CONSTRAINS


# rules
.PHONY : all
all: build

.PHONY : rebuild
rebuild: clean create build

.PHONY : create
create: $(PRJ_NAME).xpr

.PHONY : build
build: $(BIT_FILE) check_log

.PHONY : bit_scp
bit_scp: $(BIT_FILE)
	scp $(BIT_FILE) $(BOARD_ADDRESS):$(BOARD_WORK_DIR)/projects/$(BOARD_NAME)/$(PROJECT_NAME)/app

.PHONY : bit_cp
bit_cp: $(BIT_FILE)
	cp $(BIT_FILE) ../../app

$(BIT_FILE): $(SOURCES) $(CONSTRAINS) $(IP_CORES) $(BD_SCRIPTS)
	rm -f $(PRJ_NAME).xpr
	vivado -m64 -mode batch -source $(TOP_DIR)/scripts/vivado_create_project.tcl
	vivado -m64 -mode batch -source $(TOP_DIR)/scripts/vivado_implementation.tcl

.PHONY : check_log
check_log:
	@echo "----- synth_1 -----"
	@cat $(PRJ_NAME).runs/synth_1/runme.log | grep encountered.
	@echo "----- impl_1 -----"
	@cat $(PRJ_NAME).runs/impl_1/runme.log | grep encountered.

.PHONY : report_csv
report_csv:
	$(TOP_DIR)/scripts/vivado_utilization_rpt_to_csv.py $(PRJ_NAME).runs/synth_1/$(TOP_MODULE)_utilization_synth.rpt utilization_synth.csv
	$(TOP_DIR)/scripts/vivado_utilization_rpt_to_csv.py $(PRJ_NAME).runs/impl_1/$(TOP_MODULE)_utilization_placed.rpt utilization_placed.csv
	$(TOP_DIR)/scripts/vivado_timing_rpt_to_csv.py summary       $(PRJ_NAME).runs/impl_1/$(TOP_MODULE)_timing_summary_routed.rpt timing_clock_summary.csv
	$(TOP_DIR)/scripts/vivado_timing_rpt_to_csv.py intra         $(PRJ_NAME).runs/impl_1/$(TOP_MODULE)_timing_summary_routed.rpt timing_intra_clock.csv
	$(TOP_DIR)/scripts/vivado_timing_rpt_to_csv.py inter         $(PRJ_NAME).runs/impl_1/$(TOP_MODULE)_timing_summary_routed.rpt timing_inter_clock.csv
	$(TOP_DIR)/scripts/vivado_timing_rpt_to_csv.py other         $(PRJ_NAME).runs/impl_1/$(TOP_MODULE)_timing_summary_routed.rpt timing_other_path_group.csv
	$(TOP_DIR)/scripts/vivado_timing_rpt_to_csv.py ignore        $(PRJ_NAME).runs/impl_1/$(TOP_MODULE)_timing_summary_routed.rpt timing_ignore_path.csv
	$(TOP_DIR)/scripts/vivado_timing_rpt_to_csv.py unconstrained $(PRJ_NAME).runs/impl_1/$(TOP_MODULE)_timing_summary_routed.rpt timing_unconstrained_path.csv

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
