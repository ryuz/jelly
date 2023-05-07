

# get vivado version
empty:=
space:= $(empty) $(empty)
VIVADO_VERSIONS := $(subst .,$(space),$(subst v,,$(word 2,$(shell vivado -version))))
VIVADO_VERSION  := $(word 1,$(VIVADO_VERSIONS)).$(word 2,$(VIVADO_VERSIONS))

# settings
export PRJ_NAME     = ultra96v2_display_port_tcl
export TOP_MODULE   = ultra96v2_display_port
export BOARD_PART   = avnet.com:ultra96v2*
export DEVICE_PART  = xczu3eg-sbva484-1-i

# directories
TOP_DIR = ../../../../..

PRJ_DIR = ../..


# HLS IP
HLS_IP =
export HLS_IP

# sources
SOURCES  = $(PRJ_DIR)/rtl/ultra96v2_display_port.v
SOURCES += $(TOP_DIR)/rtl/v1/bus/jelly_axi4_read.v
SOURCES += $(TOP_DIR)/rtl/v1/bus/jelly_axi4_read_nd.v
SOURCES += $(TOP_DIR)/rtl/v1/bus/jelly_axi4_read_width_convert.v
SOURCES += $(TOP_DIR)/rtl/v1/bus/jelly_axi4l_to_wishbone.v
SOURCES += $(TOP_DIR)/rtl/v1/bus/jelly_axi4s_fifo.v
SOURCES += $(TOP_DIR)/rtl/v1/bus/jelly_axi4s_fifo_width_convert.v
SOURCES += $(TOP_DIR)/rtl/v1/bus/jelly_axi4s_width_convert.v
SOURCES += $(TOP_DIR)/rtl/v1/dma/jelly_dma_stream_read.v
SOURCES += $(TOP_DIR)/rtl/v1/dma/jelly_dma_video_read.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_address_align_split.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_address_generator.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_address_generator_nd.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_address_width_convert.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_capacity_async.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_capacity_buffer.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_capacity_size.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_data_async.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_data_ff.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_data_ff_pack.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_data_shift_register_lut.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_data_split_pack.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_data_split_pack2.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_fifo.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_fifo_async.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_fifo_async_fwtf.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_fifo_fwtf.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_fifo_generic_fwtf.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_fifo_pack.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_fifo_ram.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_fifo_read_fwtf.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_fifo_shifter.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_func_binary_to_graycode.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_func_graycode_to_binary.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_func_pack.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_func_unpack.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_param_update_master.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_param_update_slave.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_pipeline_control.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_pipeline_insert_ff.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_ram_simple_dualport.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_signal_transfer.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_signal_transfer_async.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_signal_transfer_sync.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_stream_add_syncflag.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_stream_gate.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_stream_width_convert.v
SOURCES += $(TOP_DIR)/rtl/v1/library/jelly_stream_width_convert_pack.v
SOURCES += $(TOP_DIR)/rtl/v1/video/jelly_vout_axi4s.v
SOURCES += $(TOP_DIR)/rtl/v1/video/jelly_vsync_adjust_de.v
SOURCES += $(TOP_DIR)/rtl/v1/video/jelly_vsync_adjust_de_core.v
SOURCES += $(TOP_DIR)/rtl/v1/video/jelly_vsync_generator.v
SOURCES += $(TOP_DIR)/rtl/v1/video/jelly_vsync_generator_core.v
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
