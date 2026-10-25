# get vivado version
empty:=
space:= $(empty) $(empty)
VIVADO_VERSIONS := $(subst .,$(space),$(subst v,,$(word 2,$(shell vivado -version))))
VIVADO_VERSION  := $(word 1,$(VIVADO_VERSIONS)).$(word 2,$(VIVADO_VERSIONS))
XILINX_VIVADO ?= /tools/Xilinx/Vivado/$(VIVADO_VERSION)

# jelly
JELLY_TOP_DIR = ../../../../..
-include $(JELLY_TOP_DIR)/include/make/def_simulation.inc

TOP_MODULE = tb_top

SIM_LIB_DIRS += ..

VLOGFLAGS  = -sv
VLOGFLAGS += --sourcelibext .v
VLOGFLAGS += --sourcelibext .sv
VLOGFLAGS += $(addprefix --sourcelibdir ,$(SIM_LIB_DIRS))

ELABFLAGS  = -debug wave

SRCS  = ../$(TOP_MODULE).sv
SRCS += $(XILINX_VIVADO)/data/verilog/src/glbl.v

.PHONY: all build run clean
all: clean build run

build:
	xvlog $(VLOGFLAGS) $(SRCS)
	xelab $(ELABFLAGS) $(TOP_MODULE) glbl -s $(TOP_MODULE) -L unisims_ver -L unimacro_ver -L secureip

run:
	xsim $(TOP_MODULE) --R

clean:
	-rm -fr xsim.dir .Xil
	-rm -f webtalk*.jou webtalk*.log xvlog*.log xvlog*.pb
	-rm -f xelab*.log xelab*.pb xsim*.jou xsim*.log