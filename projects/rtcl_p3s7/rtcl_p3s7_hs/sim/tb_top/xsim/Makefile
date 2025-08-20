
# get vivado version
empty:=
space:= $(empty) $(empty)
VIVADO_VERSIONS := $(subst .,$(space),$(subst v,,$(word 2,$(shell vivado -version))))
VIVADO_VERSION  := $(word 1,$(VIVADO_VERSIONS)).$(word 2,$(VIVADO_VERSIONS))

# setting
TOP_MODULE = tb_top

JELLY_TOP_DIR = ../../../../../..

-include $(JELLY_TOP_DIR)/include/make/def_simulation.inc

XILINX_VIVADO ?= /tools/Xilinx/Vivado/$(VIVADO_VERSION)

SRCS  = ../$(TOP_MODULE).sv
SRCS += ../../../rtl/rtcl_p3s7_hs.sv
SRCS += ../../../rtl/python_to_axi4s.sv
#SRCS += ../../stub/python_to_axi4s.sv
SRCS += ../../stub/IDDR.sv
SRCS += ../../../../../kv260/kv260_rtcl_p3s7_hs/rtl/rtcl_p3s7_hs_dphy_recv.sv
SRCS += ../../../../../kv260/kv260_rtcl_p3s7_hs/rtl/rtcl_p3s7_hs_cnv_axi4s.sv

SRCS += $(XILINX_VIVADO)/data/verilog/src/glbl.v

SRCS         += ../../../ip/vivado$(VIVADO_VERSION)/selectio_wiz_0/rtcl_p3s7_dphy.gen/sources_1/ip/selectio_wiz_0/selectio_wiz_0.v
SIM_LIB_DIRS += ../../../ip/vivado$(VIVADO_VERSION)/selectio_wiz_0/rtcl_p3s7_dphy.gen/sources_1/ip/selectio_wiz_0
SRCS         += ../../../ip/vivado$(VIVADO_VERSION)/clk_mipi_core/rtcl_p3s7_dphy.gen/sources_1/ip/clk_mipi_core/clk_mipi_core.v
SIM_LIB_DIRS += ../../../ip/vivado$(VIVADO_VERSION)/clk_mipi_core/rtcl_p3s7_dphy.gen/sources_1/ip/clk_mipi_core
SRCS         += ../../../ip/vivado$(VIVADO_VERSION)/clk_mipi_serial/rtcl_p3s7_dphy.gen/sources_1/ip/clk_mipi_serial/clk_mipi_serial.v
SIM_LIB_DIRS += ../../../ip/vivado$(VIVADO_VERSION)/clk_mipi_serial/rtcl_p3s7_dphy.gen/sources_1/ip/clk_mipi_serial
#SRCS         += ../../../ip/vivado$(VIVADO_VERSION)/mipi_dphy_0/rtcl_p3s7_dphy.gen/sources_1/ip/mipi_dphy_0/mipi_dphy_0.v
#SIM_LIB_DIRS += ../../../ip/vivado$(VIVADO_VERSION)/mipi_dphy_0/rtcl_p3s7_dphy.gen/sources_1/ip/mipi_dphy_0

SIM_LIB_DIRS += ../../stub
SIM_LIB_DIRS += ../../../rtl

VLOGFLAGS  = -sv
VLOGFLAGS += --sourcelibext .v
VLOGFLAGS += --sourcelibext .sv
VLOGFLAGS += --sourcelibdir ..
VLOGFLAGS += --sourcelibdir ../../stub
VLOGFLAGS += --sourcelibdir ../../../rtl
VLOGFLAGS += $(addprefix --sourcelibdir ,$(SIM_LIB_DIRS))
VLOGFLAGS += -i $(JELLY_TOP_DIR)/include

ELABFLAGS  = -debug wave


# rules
.PHONY: all
all: clean build run

.PHONY: build
build:
	xvlog $(VLOGFLAGS) $(SRCS)
	xelab $(ELABFLAGS) $(TOP_MODULE) glbl -s $(TOP_MODULE) -L unisims_ver -L unimacro_ver -L secureip

.PHONY: run
run:
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
	-rm -f *.vcd
	-rm -f *.wdb
