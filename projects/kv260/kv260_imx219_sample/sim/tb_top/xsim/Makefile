

# setting
TOP_MODULE = tb_top

JELLY_TOP_DIR = ../../../../../..

-include $(JELLY_TOP_DIR)/include/make/def_simulation.inc

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


# rulres
.PHONY: all
all: clean build run

.PHONY: build
build:
	xvlog $(VLOGFLAGS) $(SRCS)
	xelab $(ELABFLAGS) $(TOP_MODULE) -s $(TOP_MODULE)

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
