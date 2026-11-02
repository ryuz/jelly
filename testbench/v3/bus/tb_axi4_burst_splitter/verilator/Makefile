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
FLAGS += -Wno-SIDEEFFECT
FLAGS += $(EXTRA_FLAGS)

SRCS = ../$(TOP_MODULE).sv

.PHONY: all build clean distclean run check_write_order
all: build run

check_write_order:
	@for options in \
		'' \
		'-GWAIT_WVALID=0' \
		'-GWAIT_WLAST=1' \
		'-GWAIT_WLAST=1 -GB_DELAY=17 -GCHUNK_BEATS=128' \
		'-GWAIT_WVALID=0 -GW_EARLY=1 -GCHUNK_BEATS=1' \
		'-GWAIT_WVALID=0 -GW_EARLY=1'; do \
		$(MAKE) TOP_MODULE=tb_aw_wait_wvalid EXTRA_FLAGS="$$options" build && \
		$(MAKE) TOP_MODULE=tb_aw_wait_wvalid run || exit $$?; \
	done

build: $(SRCS)
	verilator $(FLAGS) --top $(TOP_MODULE) $(SRCS)

clean:
	rm -rf obj_dir

distclean: clean
	rm -f *.fst *.vcd

run:
	./obj_dir/V$(TOP_MODULE)