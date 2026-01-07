# get vivado version
empty:=
space:= $(empty) $(empty)
VIVADO_VERSIONS := $(subst .,$(space),$(subst v,,$(word 2,$(shell vivado -version))))
VIVADO_VERSION  := $(word 1,$(VIVADO_VERSIONS)).$(word 2,$(VIVADO_VERSIONS))

XILINX_VIVADO ?= /tools/Xilinx/Vivado/$(VIVADO_VERSION)


# setting
TOP_MODULE = tb_top

JELLY_TOP_DIR = ../../../../../../jelly
RTCL_P3S7_DIR = ../../../../../rtcl_p3s7_mipi/rtcl_p3s7_mipi

-include $(JELLY_TOP_DIR)/include/make/def_simulation.inc

SIM_LIB_DIRS += $(RTCL_P3S7_DIR)/rtl
SIM_LIB_DIRS += $(RTCL_P3S7_DIR)/sim/stub

VLOGFLAGS  = -sv
VLOGFLAGS += --sourcelibext .v
VLOGFLAGS += --sourcelibext .sv
VLOGFLAGS += --sourcelibdir ..
VLOGFLAGS += --sourcelibdir ../../stub
VLOGFLAGS += --sourcelibdir ../../../rtl
VLOGFLAGS += $(addprefix --sourcelibdir ,$(SIM_LIB_DIRS))
VLOGFLAGS += -i $(JELLY_TOP_DIR)/include

ELABFLAGS  = -debug wave

SRCS  = ../$(TOP_MODULE).sv
SRCS += ../../stub/design_1.v
SRCS += ../../stub/IOBUF.v
SRCS += ../../stub/mipi_dphy_cam.v
SRCS += ../../stub/jelly2_mipi_csi2_rx.sv

#SRCS         += $(RTCL_P3S7_DIR)/ip/vivado$(VIVADO_VERSION)/selectio_wiz_0/rtcl_p3s7_dphy.gen/sources_1/ip/selectio_wiz_0/selectio_wiz_0.v
#SIM_LIB_DIRS += $(RTCL_P3S7_DIR)/ip/vivado$(VIVADO_VERSION)/selectio_wiz_0/rtcl_p3s7_dphy.gen/sources_1/ip/selectio_wiz_0
#SRCS         += $(RTCL_P3S7_DIR)/ip/vivado$(VIVADO_VERSION)/clk_mipi_core/rtcl_p3s7_dphy.gen/sources_1/ip/clk_mipi_core/clk_mipi_core.v
#SIM_LIB_DIRS += $(RTCL_P3S7_DIR)/ip/vivado$(VIVADO_VERSION)/clk_mipi_core/rtcl_p3s7_dphy.gen/sources_1/ip/clk_mipi_core
#SRCS         += $(RTCL_P3S7_DIR)/ip/vivado$(VIVADO_VERSION)/clk_mipi_serial/rtcl_p3s7_dphy.gen/sources_1/ip/clk_mipi_serial/clk_mipi_serial.v
#SIM_LIB_DIRS += $(RTCL_P3S7_DIR)/ip/vivado$(VIVADO_VERSION)/clk_mipi_serial/rtcl_p3s7_dphy.gen/sources_1/ip/clk_mipi_serial

SRCS += $(XILINX_VIVADO)/data/verilog/src/glbl.v


# rulres
.PHONY: all
all: clean build run

.PHONY: build
build:
	xvlog $(VLOGFLAGS) $(SRCS)
	xelab $(ELABFLAGS) $(TOP_MODULE) glbl -s $(TOP_MODULE) -L unisims_ver -L unimacro_ver -L secureip -L xpm

.PHONY: run
run:
	mkdir -p output
	xsim $(TOP_MODULE) --R

.PHONY: clean
clean:
	-rm -fr xsim.dir
	-rm -fr .Xil
	-rm -f webtalk*.jou
	-rm -f webtalk*.log
	-rm -f xvlog*.log
	-rm -f xvlog*.pb
	-rm -f xelab*.log
	-rm -f xelab*.pb
	-rm -f xsim*.jou
	-rm -f xsim*.log

.PHONY: distclean
distclean: clean
	-rm -fr output
	-rm -f *.pgm
	-rm -f *.ppm
	-rm -f $(TOP_MODULE).vcd
	-rm -f $(TOP_MODULE).wdb
