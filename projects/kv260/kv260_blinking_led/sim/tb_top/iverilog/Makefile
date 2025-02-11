# setting
TOP_MODULE = tb_top

VLOGFLAGS  = -sv

SRCS  = ../tb_top.sv
SRCS += ../../stub/design_1.v
SRCS += ../../../rtl/kv260_blinking_led.sv


# rules
.PHONY: all
all: clean build run

.PHONY: build
build:
	iverilog -g2012 -o $(TOP_MODULE).vvp -s $(TOP_MODULE) $(SRCS)

.PHONY: run
run:
	vvp $(TOP_MODULE).vvp


.PHONY: vcd2fst
vcd2fst:
	vcd2fst $(TOP_MODULE).vcd $(TOP_MODULE).fst

.PHONY: clean
clean:
	-rm -f $(TOP_MODULE).vvp

.PHONY: distclean
distclean: clean
	-rm -f *.vcd
