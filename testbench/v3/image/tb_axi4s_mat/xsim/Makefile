
# get vivado version
empty:=
space:= $(empty) $(empty)
VIVADO_VERSIONS := $(subst .,$(space),$(subst v,,$(word 2,$(shell vivado -version))))
VIVADO_VERSION  := $(word 1,$(VIVADO_VERSIONS)).$(word 2,$(VIVADO_VERSIONS))
XILINX_VIVADO ?= /tools/Xilinx/Vivado/$(VIVADO_VERSION)

# jelly
JELLY_TOP_DIR = ../../../../..
-include $(JELLY_TOP_DIR)/include/make/def_simulation.inc

# setting
TOP_MODULE = tb_top

SIM_LIB_DIRS += ..

VLOGFLAGS  = -sv
VLOGFLAGS += --sourcelibext .v
VLOGFLAGS += --sourcelibext .sv
VLOGFLAGS += $(addprefix --sourcelibdir ,$(SIM_LIB_DIRS))

ELABFLAGS  = -debug wave
 
SRCS  = ../$(TOP_MODULE).sv
SRCS += $(XILINX_VIVADO)/data/verilog/src/glbl.v


# rules
.PHONY: all
all: clean build run

.PHONY: build
build:
	xvlog $(VLOGFLAGS) $(SRCS)
	xelab $(ELABFLAGS) $(TOP_MODULE) glbl -s $(TOP_MODULE) -L unisims_ver -L unimacro_ver -L secureip
#	xelab $(ELABFLAGS) $(TOP_MODULE) glbl -s $(TOP_MODULE) -L unisims_ver -L unimacro_ver -L secureip -L uvm -timescale 1ns/1ps

.PHONY: run
run:
	mkdir -p output
	xsim $(TOP_MODULE) --R
	diff output/exp_0000.pgm output/img_0000.pgm
	diff output/exp_0000.pgm output/img_0006.pgm


.PHONY: vcd2fst
vcd2fst:
	vcd2fst $(TOP_MODULE).vcd $(TOP_MODULE).fst

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
	-rm -f *.pgm
	-rm -f *.ppm
	-rm -f axi4_*.txt
