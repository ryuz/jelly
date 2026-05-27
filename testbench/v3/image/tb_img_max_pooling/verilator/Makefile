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
MODE   ?= unsigned

INPUT_IMG    = ../pattern/input_0000.ppm
EXPECTED_IMG = expected_0000.ppm
DUT_IMG      = dut_0000.ppm

# Determine IS_SIGNED based on MODE
ifeq ($(MODE),signed)
    IS_SIGNED = 1
    OBJ_DIR = obj_dir_signed
    DUT_IMG_ACTUAL = dut_0000_signed.ppm
    EXPECTED_IMG_ACTUAL = expected_0000_signed.ppm
else
    IS_SIGNED = 0
    OBJ_DIR = obj_dir
    DUT_IMG_ACTUAL = $(DUT_IMG)
    EXPECTED_IMG_ACTUAL = $(EXPECTED_IMG)
endif

all: gen build run diff

all-both: all all-signed

.PHONY : all-signed
all-signed: clean-signed gen-signed build-signed run-signed diff-signed

.PHONY : gen
gen:
	$(PYTHON) ../gen_images.py --width $(WIDTH) --height $(HEIGHT) --n $(POOL_N) --m $(POOL_M) --operation max --mode $(MODE) --input $(INPUT_IMG) --expected $(EXPECTED_IMG_ACTUAL)

.PHONY : gen-signed
gen-signed:
	$(MAKE) gen MODE=signed

.PHONY : build
build: $(SRCS)
	mkdir -p $(OBJ_DIR)
	mkdir -p tmp_$(MODE)
	sed 's/parameter.*bit.*IS_SIGNED.*/parameter   bit     IS_SIGNED           = 1'\''b$(IS_SIGNED)/' ../$(TOP_MODULE).sv > tmp_$(MODE)/$(TOP_MODULE)_tmp.sv
	verilator $(FLAGS) --top $(TOP_MODULE) tmp_$(MODE)/$(TOP_MODULE)_tmp.sv -o V$(TOP_MODULE) -Mdir $(OBJ_DIR)

.PHONY : build-signed
build-signed:
	$(MAKE) build MODE=signed

.PHONY : run
run:
	./$(OBJ_DIR)/V$(TOP_MODULE)
	@if [ "$(MODE)" = "signed" ]; then mv dut_0000.ppm dut_0000_signed.ppm; fi

.PHONY : run-signed
run-signed:
	$(MAKE) run MODE=signed

.PHONY : diff
diff:
	diff -u $(EXPECTED_IMG_ACTUAL) $(DUT_IMG_ACTUAL)

.PHONY : diff-signed
diff-signed:
	$(MAKE) diff MODE=signed

.PHONY : clean
clean:
	rm -rf obj_dir obj_dir_signed tmp_unsigned tmp_signed
	rm -f $(DUT_IMG) $(EXPECTED_IMG) dut_0000_signed.ppm expected_0000_signed.ppm

.PHONY : clean-signed
clean-signed:
	rm -rf obj_dir_signed
	rm -f dut_0000_signed.ppm expected_0000_signed.ppm

.PHONY : distclean
distclean: clean clean-signed
	rm -f *.fst *.vcd
	rm -f ../pattern/input_*.ppm
