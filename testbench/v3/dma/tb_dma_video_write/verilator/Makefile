

# setting
TOP_MODULE = tb_dma_video_write

JELLY_TOP_DIR = ../../../../..

-include $(JELLY_TOP_DIR)/include/make/def_simulation.inc


FLAGS  = --binary -j 0
FLAGS += --assert
FLAGS += --trace-fst --trace-params --trace-structs --trace-underscore
FLAGS += -D__VERILATOR__ -D__SIMULATION__
FLAGS += $(addprefix -y ,$(SIM_LIB_DIRS))
#FLAGS += -Wall
#FLAGS += -Wno-WIDTH
#FLAGS += -Wno-PINCONNECTEMPTY
#FLAGS += -Wno-UNUSEDPARAM
#FLAGS += -Wno-UNUSEDSIGNAL
#FLAGS += -Wno-UNUSEDPARAM
#FLAGS += -Wno-WIDTHTRUNC
#FLAGS += -Wno-fatal

SRCS = ../$(TOP_MODULE).sv


# rulres
all: build run

.PHONY : build
build:
	verilator $(FLAGS) --top $(TOP_MODULE) $(SRCS)

.PHONY : run
run:
	./obj_dir/V$(TOP_MODULE)

.PHONY : coverage
coverage:
	verilator_coverage --annotate annotated coverage.dat


.PHONY : clean
clean:
	rm -rf obj_dir

.PHONY : distclean
distclean: clean
	rm -f *.fst *.vcd
	rm -f *.ppm *.pgm
	rm -f axi*.txt
	rm -f coverage.dat
	rm -fr annotated
