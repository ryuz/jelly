

# get vivado version
empty:=
space:= $(empty) $(empty)
VIVADO_VERSIONS := $(subst .,$(space),$(subst v,,$(word 2,$(shell vivado -version))))
VIVADO_VERSION  := $(word 1,$(VIVADO_VERSIONS)).$(word 2,$(VIVADO_VERSIONS))

# settings
PROJECT_NAME = zybo_z7_necolink_lan8720
export PRJ_NAME     = $(PROJECT_NAME)_tcl
export TOP_MODULE   = $(PROJECT_NAME)
export BOARD_PART   = digilentinc.com:zybo-z7-20*
export DEVICE_PART  = xc7z020clg400-1

BOARD_ADDRESS  ?= debian-zybo-z7
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

# Jellyvl
JELLYVL_DIR = $(TOP_DIR)/jellyvl/sv

# sources
SOURCES  = $(PRJ_DIR)/rtl/zybo_z7_necolink_lan8720.sv
SOURCES += $(PRJ_DIR)/rtl/rmii_to_pmod.sv
SOURCES += $(PRJ_DIR)/rtl/rmii_phy.sv
SOURCES += $(PRJ_DIR)/rtl/timer_trigger_interval_core.sv
SOURCES += $(PRJ_DIR)/rtl/timer_trigger_oneshot_core.sv
SOURCES += $(PRJ_DIR)/rtl/timer_generate_pulse_core.sv
SOURCES += $(JELLYVL_DIR)/jellyvl_data_delay.sv
SOURCES += $(JELLYVL_DIR)/jellyvl_divider_unsigned_multicycle.sv
SOURCES += $(JELLYVL_DIR)/jellyvl_etherneco_master.sv
SOURCES += $(JELLYVL_DIR)/jellyvl_etherneco_packet_rx.sv
SOURCES += $(JELLYVL_DIR)/jellyvl_etherneco_packet_tx.sv
SOURCES += $(JELLYVL_DIR)/jellyvl_etherneco_slave.sv
SOURCES += $(JELLYVL_DIR)/jellyvl_etherneco_synctimer_master.sv
SOURCES += $(JELLYVL_DIR)/jellyvl_etherneco_synctimer_slave.sv
SOURCES += $(JELLYVL_DIR)/jellyvl_etherneco_synctimer_slave_core.sv
SOURCES += $(JELLYVL_DIR)/jellyvl_periodic_trigger.sv
SOURCES += $(JELLYVL_DIR)/jellyvl_stream_ff.sv
SOURCES += $(JELLYVL_DIR)/jellyvl_synctimer_adjuster.sv
SOURCES += $(JELLYVL_DIR)/jellyvl_synctimer_adjuster_calc.sv
SOURCES += $(JELLYVL_DIR)/jellyvl_synctimer_adjuster_driver.sv
SOURCES += $(JELLYVL_DIR)/jellyvl_synctimer_core.sv
SOURCES += $(JELLYVL_DIR)/jellyvl_synctimer_timer.sv
SOURCES += $(JELLYVL_DIR)/jellyvl_synctimer_limitter.sv
SOURCES += $(JELLY_RTL_SOURCES)

export SOURCES

# IP cores
IP_CORES =
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
build: $(BIT_FILE) check_log

.PHONY : bit_scp
bit_scp: $(BIT_FILE)
	scp $(BIT_FILE) $(BOARD_ADDRESS):$(BOARD_WORK_DIR)/projects/$(PROJECT_NAME)/app

.PHONY : bit_cp
bit_cp: $(BIT_FILE)
	cp $(BIT_FILE) ../../app

$(PRJ_NAME).xpr: $(IP_CORES) $(BD_SCRIPTS) Makefile
	rm -f $(PRJ_NAME).xpr
	vivado -m64 -mode batch -source $(TOP_DIR)/scripts/vivado_create_project.tcl

$(BIT_FILE): $(PRJ_NAME).xpr $(SOURCES) $(CONSTRAINS) 
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
	-rm -f $(PRJ_NAME).xpr
	-rm -f vivado*.jou
	-rm -f vivado*.log
