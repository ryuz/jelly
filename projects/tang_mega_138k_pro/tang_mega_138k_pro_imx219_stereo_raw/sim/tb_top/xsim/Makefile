

# setting
TOP_MODULE = tb_top

JELLY_TOP_DIR = ../../../../../..

-include $(JELLY_TOP_DIR)/include/make/def_simulation.inc

SIM_LIB_DIRS += ..
SIM_LIB_DIRS += ../../stub
SIM_LIB_DIRS += ../../../rtl

VLOGFLAGS  = -sv
VLOGFLAGS += --sourcelibext .v
VLOGFLAGS += --sourcelibext .sv
VLOGFLAGS += $(addprefix --sourcelibdir ,$(SIM_LIB_DIRS))

ELABFLAGS  = -debug wave

SRCS  = ../$(TOP_MODULE).sv
SRCS += ../tb_main.sv
SRCS += ../jfive_tcm.sv

# rulres
.PHONY: all
all: clean build run

.PHONY: build
build:
	make -C ../../../jfive
	cp ../../../jfive/mem.hex ../
	xvlog $(VLOGFLAGS) $(SRCS)
	xelab $(ELABFLAGS) $(TOP_MODULE) -s $(TOP_MODULE)

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
	-rm -f *.pgm
	-rm -f *.ppm
	-rm -f axi4_*.txt
	-rm -f $(TOP_MODULE).vcd
	-rm -f $(TOP_MODULE).wdb
