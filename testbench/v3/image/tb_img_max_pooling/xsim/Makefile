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
ifeq ($(XILINX_VIVADO),)
GLBL_V =
else
GLBL_V = $(XILINX_VIVADO)/data/verilog/src/glbl.v
SRCS += $(GLBL_V)
endif

PYTHON ?= python3
WIDTH  ?= 16
HEIGHT ?= 12
POOL_N ?= 3
POOL_M ?= 3
MODE   ?= unsigned

INPUT_IMG    = ../pattern/input_0000.ppm
EXPECTED_IMG = expected_0000.ppm
DUT_IMG      = dut_0000.ppm

# Determine IS_SIGNED based on MODE
ifeq ($(MODE),signed)
    IS_SIGNED = 1
    XSIM_DIR = xsim_signed
    SIM_NAME = $(TOP_MODULE)_signed
    DUT_IMG_ACTUAL = dut_0000_signed.ppm
    EXPECTED_IMG_ACTUAL = expected_0000_signed.ppm
else
    IS_SIGNED = 0
    XSIM_DIR = .
    SIM_NAME = $(TOP_MODULE)
    DUT_IMG_ACTUAL = $(DUT_IMG)
    EXPECTED_IMG_ACTUAL = $(EXPECTED_IMG)
endif

.PHONY: all
all: clean gen build run diff

.PHONY: all-both
all-both: all all-signed

.PHONY: all-signed
all-signed: clean-signed gen-signed build-signed run-signed diff-signed

.PHONY : gen
gen:
	$(PYTHON) ../gen_images.py --width $(WIDTH) --height $(HEIGHT) --n $(POOL_N) --m $(POOL_M) --operation max --mode $(MODE) --input $(INPUT_IMG) --expected $(EXPECTED_IMG_ACTUAL)

.PHONY : gen-signed
gen-signed:
	$(MAKE) gen MODE=signed

.PHONY: build
build: gen
	mkdir -p tmp_$(MODE)
	sed 's/parameter.*bit.*IS_SIGNED.*/parameter   bit     IS_SIGNED           = 1'\''b$(IS_SIGNED)/' ../$(TOP_MODULE).sv > tmp_$(MODE)/$(TOP_MODULE)_tmp.sv
	xvlog $(VLOGFLAGS) tmp_$(MODE)/$(TOP_MODULE)_tmp.sv
	xelab $(ELABFLAGS) $(TOP_MODULE) glbl -s $(SIM_NAME) -L unisims_ver -L unimacro_ver -L secureip

.PHONY: build-signed
build-signed:
	$(MAKE) build MODE=signed

.PHONY: run
run:
	xsim $(SIM_NAME) --R
	@if [ "$(MODE)" = "signed" ]; then mv dut_0000.ppm dut_0000_signed.ppm; fi

.PHONY: run-signed
run-signed:
	$(MAKE) run MODE=signed

.PHONY : diff
diff:
	diff -u $(EXPECTED_IMG_ACTUAL) $(DUT_IMG_ACTUAL)

.PHONY : diff-signed
diff-signed:
	$(MAKE) diff MODE=signed

.PHONY: clean
clean:
	-rm -fr xsim.dir
	-rm -fr .Xil
	-rm -fr tmp_unsigned tmp_signed
	-rm -f webtalk*.jou
	-rm -f webtalk*.log
	-rm -f xvlog*.log
	-rm -f xvlog*.pb
	-rm -f xelab*.log
	-rm -f xelab*.pb
	-rm -f xsim*.jou
	-rm -f xsim*.log
	-rm -f $(DUT_IMG) $(EXPECTED_IMG)

.PHONY: clean-signed
clean-signed:
	-rm -fr xsim_signed.dir
	-rm -f xsim_signed.*
	-rm -f dut_0000_signed.ppm expected_0000_signed.ppm

.PHONY: distclean
distclean: clean clean-signed
	-rm -f *.vcd
	-rm -f *.wdb
	-rm -f ../pattern/input_*.ppm
