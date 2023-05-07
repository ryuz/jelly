

# get vivado version
empty:=
space:= $(empty) $(empty)
VIVADO_VERSIONS := $(subst .,$(space),$(subst v,,$(word 2,$(shell vivado -version))))
VIVADO_VERSION  := $(word 1,$(VIVADO_VERSIONS)).$(word 2,$(VIVADO_VERSIONS))

# settings
export PRJ_NAME     = kv260_mpu9250_tcl
export TOP_MODULE   = kv260_mpu9250
export BOARD_PART   = xilinx.com:kv260_som*
export DEVICE_PART  =

# directories
TOP_DIR = ../../../..
PRJ_DIR = ../..


# HLS IP
HLS_IP =
export HLS_IP

# sources
SOURCES  = $(PRJ_DIR)/rtl/kv260_mpu9250.sv
SOURCES += $(TOP_DIR)/rtl/bus/jelly_axi4l_to_wishbone.v
SOURCES += $(TOP_DIR)/rtl/peripheral/jelly_interval_timer.v
SOURCES += $(TOP_DIR)/rtl/peripheral/jelly_i2c.v
SOURCES += $(TOP_DIR)/rtl/peripheral/jelly_i2c_core.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_pipeline_control.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_pipeline_insert_ff.v
SOURCES += $(TOP_DIR)/rtl/misc/jelly2_communication_pipe.sv
SOURCES += $(TOP_DIR)/rtl/misc/jelly2_communication_pipes.sv
SOURCES += $(TOP_DIR)/rtl/library/jelly2_data_shift_register_lut.sv
SOURCES += $(TOP_DIR)/rtl/library/jelly2_fifo.sv
SOURCES += $(TOP_DIR)/rtl/library/jelly2_fifo_fwtf.sv
SOURCES += $(TOP_DIR)/rtl/library/jelly2_fifo_ram.sv
SOURCES += $(TOP_DIR)/rtl/library/jelly2_fifo_read_fwtf.sv
SOURCES += $(TOP_DIR)/rtl/library/jelly2_fifo_shifter.sv
SOURCES += $(TOP_DIR)/rtl/library/jelly2_ram_simple_dualport.sv
SOURCES += $(TOP_DIR)/rtl/rtos/jelly2_rtos.sv
SOURCES += $(TOP_DIR)/rtl/rtos/jelly2_rtos_core.sv
SOURCES += $(TOP_DIR)/rtl/rtos/jelly2_rtos_eventflag.sv
SOURCES += $(TOP_DIR)/rtl/rtos/jelly2_rtos_queue.sv
SOURCES += $(TOP_DIR)/rtl/rtos/jelly2_rtos_queue_fifo.sv
SOURCES += $(TOP_DIR)/rtl/rtos/jelly2_rtos_queue_priority.sv
SOURCES += $(TOP_DIR)/rtl/rtos/jelly2_rtos_semaphore.sv
SOURCES += $(TOP_DIR)/rtl/rtos/jelly2_rtos_task.sv
SOURCES += $(TOP_DIR)/rtl/rtos/jelly2_rtos_timer.sv

export SOURCES


# IP cores
IP_CORES  =
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
