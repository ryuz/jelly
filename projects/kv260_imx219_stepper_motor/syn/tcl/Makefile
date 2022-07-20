

# get vivado version
empty:=
space:= $(empty) $(empty)
VIVADO_VERSIONS := $(subst .,$(space),$(subst v,,$(word 2,$(shell vivado -version))))
VIVADO_VERSION  := $(word 1,$(VIVADO_VERSIONS)).$(word 2,$(VIVADO_VERSIONS))

# settings
export PRJ_NAME     = kv260_imx219_stepper_motor_tcl
export TOP_MODULE   = kv260_imx219_stepper_motor
export BOARD_PART   = xilinx.com:kv260_som*
export DEVICE_PART  =

# directories
TOP_DIR = ../../../..
PRJ_DIR = ../..


# HLS IP
HLS_IP =
export HLS_IP

# sources
SOURCES  = $(PRJ_DIR)/rtl/kv260_imx219_stepper_motor.sv
SOURCES += $(PRJ_DIR)/rtl/image_processing.sv
SOURCES += $(PRJ_DIR)/rtl/stepper_moter_pwm.sv
SOURCES += $(TOP_DIR)/rtl/bus/jelly_axi4_dma_addr.v
SOURCES += $(TOP_DIR)/rtl/bus/jelly_axi4_dma_writer.v
SOURCES += $(TOP_DIR)/rtl/bus/jelly_axi4l_to_wishbone.v
SOURCES += $(TOP_DIR)/rtl/image/jelly2_img_rgb2hsv.sv
SOURCES += $(TOP_DIR)/rtl/image/jelly2_rgb2hsv.sv
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_blk_buffer.v
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_color_matrix.v
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_color_matrix_core.v
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_delay.v
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_demosaic_acpi.v
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_demosaic_acpi_core.v
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_demosaic_acpi_g_core.v
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_demosaic_acpi_g_calc.v
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_demosaic_acpi_rb_core.v
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_demosaic_acpi_rb_calc.v
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_gaussian_3x3.v
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_gaussian_3x3_core.v
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_gaussian_3x3_calc.v
SOURCES += $(TOP_DIR)/rtl/image/jelly2_img_rgb2hsv.sv
SOURCES += $(TOP_DIR)/rtl/image/jelly2_img_binarizer.sv
SOURCES += $(TOP_DIR)/rtl/image/jelly2_img_binarizer_core.sv
SOURCES += $(TOP_DIR)/rtl/image/jelly2_img_binarizer_calc.sv
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_line_buffer.v
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_pixel_buffer.v
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_selector.v
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_selector_core.v
SOURCES += $(TOP_DIR)/rtl/image/jelly_img_to_axi4s.v
SOURCES += $(TOP_DIR)/rtl/image/jelly2_img_delay.sv
SOURCES += $(TOP_DIR)/rtl/image/jelly2_axi4s_img_simple.sv
SOURCES += $(TOP_DIR)/rtl/image/jelly2_axi4s_to_img_simple.sv
SOURCES += $(TOP_DIR)/rtl/image/jelly2_img_to_axi4s.sv
SOURCES += $(TOP_DIR)/rtl/peripheral/jelly_interval_timer.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_data_delay.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_data_ff.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_data_ff_pack.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_data_shift_register_lut.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_data_width_converter.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_demultiplexer.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_fifo.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_fifo_async.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_fifo_async_fwtf.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_fifo_fwtf.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_fifo_generic_fwtf.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_fifo_ram.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_fifo_read_fwtf.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_fifo_shifter.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_func_binary_to_graycode.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_func_graycode_to_binary.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_func_pack.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_func_unpack.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_multiplexer.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_param_update_master.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_param_update_slave.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_pipeline_control.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_pipeline_insert_ff.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_pulse_async.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_ram_simple_dualport.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_ram_singleport.v
SOURCES += $(TOP_DIR)/rtl/library/jelly_stream_width_convert.v
SOURCES += $(TOP_DIR)/rtl/math/jelly_fixed_matrix3x4.v
SOURCES += $(TOP_DIR)/rtl/math/jelly_integer_divider.v
SOURCES += $(TOP_DIR)/rtl/primitive/jelly_mul_add3.v
SOURCES += $(TOP_DIR)/rtl/primitive/jelly_mul_add_dsp48e1.v
SOURCES += $(TOP_DIR)/rtl/video/jelly_mipi_csi2_rx.v
SOURCES += $(TOP_DIR)/rtl/video/jelly_mipi_csi2_rx_low_layer.v
SOURCES += $(TOP_DIR)/rtl/video/jelly_mipi_csi2_rx_raw10.v
SOURCES += $(TOP_DIR)/rtl/video/jelly_mipi_ecc24.v
SOURCES += $(TOP_DIR)/rtl/video/jelly_mipi_rx_lane.v
SOURCES += $(TOP_DIR)/rtl/video/jelly_mipi_rx_lane_recv.v
SOURCES += $(TOP_DIR)/rtl/video/jelly_mipi_rx_lane_sync.v
SOURCES += $(TOP_DIR)/rtl/video/jelly_vdma_axi4s_to_axi4.v
SOURCES += $(TOP_DIR)/rtl/video/jelly_vdma_axi4s_to_axi4_control.v
SOURCES += $(TOP_DIR)/rtl/video/jelly_vdma_axi4s_to_axi4_core.v
SOURCES += $(TOP_DIR)/rtl/video/jelly_video_format_regularizer.v
SOURCES += $(TOP_DIR)/rtl/video/jelly_video_format_regularizer_core.v
SOURCES += $(TOP_DIR)/rtl/rtos/jelly_rtos_axi4l.v
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
IP_CORES = $(PRJ_DIR)/ip/vivado$(VIVADO_VERSION)/mipi_dphy_cam/mipi_dphy_cam.xci
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
