# setting
TOP_MODULE = tb_top

FLAGS  = --binary --trace-fst

SRCS  = ./tb_top.sv
SRCS += ../../stub/design_1.v
SRCS += ../../../rtl/kv260_blinking_led.sv

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
	rm -f *.vcd
