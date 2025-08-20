
# setting
TOP_MODULE = tb_top

JELLY_TOP_DIR = ../../../../../..

-include $(JELLY_TOP_DIR)/include/make/def_simulation.inc

SIM_LIB_DIRS += ../../stub
SIM_LIB_DIRS += ../../../rtl

FLAGS  = --binary -j 0
#FLAGS += --assert
FLAGS += --trace-fst --trace-params --trace-structs --trace-underscore
FLAGS += -D__VERILATOR__ -D__SIMULATION__
FLAGS += $(addprefix -y ,$(SIM_LIB_DIRS))

SRCS  = ../$(TOP_MODULE).sv

all: build run

.PHONY : build
build: $(SRCS)
	verilator $(FLAGS) --top $(TOP_MODULE) $(SRCS)

.PHONY : run
run:
	./obj_dir/V$(TOP_MODULE)

.PHONY : clean
clean:
	rm -rf obj_dir

.PHONY : distclean
distclean: clean
	rm -f *.fst *.vcd
