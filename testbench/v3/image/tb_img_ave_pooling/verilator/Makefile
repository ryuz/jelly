# jelly
JELLY_TOP_DIR = ../../../../..
-include $(JELLY_TOP_DIR)/include/make/def_simulation.inc

# setting
TOP_MODULE = tb_top

SIM_LIB_DIRS += ..

FLAGS  = --binary -j 0
FLAGS += --assert
FLAGS += --trace-fst --trace-params --trace-structs --trace-underscore
FLAGS += -D__VERILATOR__ -D__SIMULATION__
FLAGS += $(addprefix -y ,$(SIM_LIB_DIRS))
FLAGS += -Wno-SIDEEFFECT

SRCS  = ../$(TOP_MODULE).sv

PYTHON ?= python3
WIDTH  ?= 16
HEIGHT ?= 12
POOL_N ?= 3
POOL_M ?= 3
MUL    ?= 28
SHIFT  ?= 8
OUT_BITS ?= 8

INPUT_IMG    = ../pattern/input_0000.ppm
EXPECTED_IMG = expected_0000.ppm
DUT_IMG      = dut_0000.ppm

all: clean gen build run diff

.PHONY : gen
gen:
	$(PYTHON) ../gen_images.py --width $(WIDTH) --height $(HEIGHT) --n $(POOL_N) --m $(POOL_M) --mul $(MUL) --shift $(SHIFT) --out-bits $(OUT_BITS) --input $(INPUT_IMG) --expected $(EXPECTED_IMG)

.PHONY : build
build: $(SRCS)
	verilator $(FLAGS) --top $(TOP_MODULE) $(SRCS)

.PHONY : run
run:
	./obj_dir/V$(TOP_MODULE)

.PHONY : diff
diff:
	diff -u $(EXPECTED_IMG) $(DUT_IMG)

.PHONY : clean
clean:
	rm -rf obj_dir
	rm -f $(DUT_IMG) $(EXPECTED_IMG)

.PHONY : distclean
distclean: clean
	rm -f *.fst *.vcd
	rm -f ../pattern/input_*.ppm
