# jelly
JELLY_TOP_DIR = ../../../../..
-include $(JELLY_TOP_DIR)/include/make/def_simulation.inc

TOP_MODULE = tb_top
SIM_LIB_DIRS += ..

FLAGS  = --binary -j 0
FLAGS += --assert
FLAGS += --trace-fst --trace-params --trace-structs --trace-underscore
FLAGS += -D__VERILATOR__ -D__SIMULATION__
FLAGS += $(addprefix -y ,$(SIM_LIB_DIRS))

SRCS = ../$(TOP_MODULE).sv

.PHONY: all build clean distclean run
all: build run

build: $(SRCS)
	verilator $(FLAGS) --top $(TOP_MODULE) $(SRCS)

clean:
	rm -rf obj_dir

distclean: clean
	rm -f *.fst *.vcd

run:
	./obj_dir/V$(TOP_MODULE)