
# setting
TOP_MODULE = tb_top

VLOGFLAGS  = -sv

SRCS  = ../tb_top.sv
SRCS += ../../stub/design_1.v
SRCS += ../../../rtl/kr260_blinking_led.sv


# rules
.PHONY: all
all: clean build run

.PHONY: build
build:
	xvlog $(VLOGFLAGS) $(SRCS)
	xelab $(TOP_MODULE)

.PHONY: run
run:
	xsim $(TOP_MODULE) --R


.PHONY: clean
clean:
	-rm -fr xsim.dir
	-rm -fr .Xil
	-rm -f webtalk*.jou
	-rm -f webtalk*.log
	-rm -f xvlog*.log
	-rm -f xvlog*.pb
	-rm -f xelab*.log
	-rm -f xelab*.pb
	-rm -f xsim*.jou
	-rm -f xsim*.log

.PHONY: distclean
distclean: clean
	-rm -f *.vcd
	-rm -f *.wdb
