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
FLAGS += $(EXTRA_FLAGS)

SRCS = ../$(TOP_MODULE).sv

.PHONY: all build clean distclean run check_all
all: build run

# sweep bus widths, FIFO depths, stall rates, aclken gating and downstream queueing
check_all:
	@for options in \
		'' \
		'-GDATA_BITS=8' \
		'-GDATA_BITS=64 -GCKE_BUSY_RATE=30' \
		'-GDATA_BITS=512 -GNUM_TESTS=256' \
		'-GDATA_BITS=512 -GNUM_TESTS=256 -GFIFO_PTR_BITS=1 -GMAX_OUTSTANDING=16' \
		'-GFIFO_PTR_BITS=1 -GBUSY_RATE=70' \
		'-GBUSY_RATE=0 -GMAX_OUTSTANDING=32' \
		'-GMODEL_FIFO_PTR_BITS=3 -GMAX_OUTSTANDING=16'; do \
		echo "=== $$options ==="; \
		$(MAKE) EXTRA_FLAGS="$$options" build && $(MAKE) run || exit $$?; \
	done

build: $(SRCS)
	verilator $(FLAGS) --top $(TOP_MODULE) $(SRCS)

clean:
	rm -rf obj_dir

distclean: clean
	rm -f *.fst *.vcd

run:
	./obj_dir/V$(TOP_MODULE)