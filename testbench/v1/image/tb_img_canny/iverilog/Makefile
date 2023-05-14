

TOP_MODULE=tb_sim

.PHONY: all
all: clean build run

.PHONY: build
build:
	iverilog -o $(TOP_MODULE).vvp -s $(TOP_MODULE) -c iverilog_cmd.txt -DIVERILOG

.PHONY: run
run:
	vvp $(TOP_MODULE).vvp
	

.PHONY: clean
clean:
	-rm -f $(TOP_MODULE).vvp

.PHONY: distclean
distclean: clean
	-rm -f *.ppm
	-rm -f *.pgm
	-rm -f $(TOP_MODULE).vcd
