

# get vivado version
empty:=
space:= $(empty) $(empty)
VIVADO_VERSIONS := $(subst .,$(space),$(subst v,,$(word 2,$(shell vivado -version))))
VIVADO_VERSION  := $(word 1,$(VIVADO_VERSIONS)).$(word 2,$(VIVADO_VERSIONS))

# settings
PROJECT_NAME = rtcl_p3s7_dphy
BOARD_NAME   = 
export PRJ_NAME     = $(PROJECT_NAME)_tcl
export TOP_MODULE   = $(PROJECT_NAME)
export BOARD_PART   =
export DEVICE_PART  = xc7s6ftgb196-2


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
SOURCES  = $(PRJ_DIR)/rtl/rtcl_p3s7_dphy.sv
SOURCES += $(PRJ_DIR)/rtl/sensor_pwr_mng.sv
SOURCES += $(PRJ_DIR)/rtl/mipi_dphy_clk_gen.sv
SOURCES += $(PRJ_DIR)/rtl/py300_control.sv
SOURCES += $(PRJ_DIR)/rtl/python_spi.sv
SOURCES += $(PRJ_DIR)/rtl/i2c_to_spi.sv
#SOURCES += $(PRJ_DIR)/rtl/pttern_align_10bit.sv
SOURCES += $(JELLY_RTL_SOURCES)
export SOURCES

# IP cores
IP_CORES  = $(PRJ_DIR)/ip/vivado$(VIVADO_VERSION)/clk_mipi_core/clk_mipi_core.xci
IP_CORES += $(PRJ_DIR)/ip/vivado$(VIVADO_VERSION)/clk_mipi_serial/clk_mipi_serial.xci
IP_CORES += $(PRJ_DIR)/ip/vivado$(VIVADO_VERSION)/mipi_dphy_0/mipi_dphy_0.xci
IP_CORES += $(PRJ_DIR)/ip/vivado$(VIVADO_VERSION)/selectio_wiz_0/selectio_wiz_0.xci
export IP_CORES

# block design
BD_SCRIPTS =
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
build: $(BIT_FILE) check_log


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
