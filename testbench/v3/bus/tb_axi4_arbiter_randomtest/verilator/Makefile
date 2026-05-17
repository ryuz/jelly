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
# s_axi4.ID_BITS (2) < m_axi4.ID_BITS (4): zero-extend on input, truncate-upper-zeros on response path
FLAGS += -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC

SRCS  = ../$(TOP_MODULE).sv

all: build run

.PHONY : build
build: $(SRCS)
	verilator $(FLAGS) --top $(TOP_MODULE) $(SRCS)

.PHONY : clean
clean:
	rm -rf obj_dir

.PHONY : distclean
distclean: clean
	rm -f *.fst *.vcd

.PHONY : run
run:
	./obj_dir/V$(TOP_MODULE)
