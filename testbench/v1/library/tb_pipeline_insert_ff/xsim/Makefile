# get vivado version
empty:=
space:= $(empty) $(empty)
VIVADO_VERSIONS := $(subst .,$(space),$(subst v,,$(word 2,$(shell vivado -version))))
VIVADO_VERSION  := $(word 1,$(VIVADO_VERSIONS)).$(word 2,$(VIVADO_VERSIONS))


# setting
TOP_MODULE = tb_pipeline_insert_ff


# rules
.PHONY: all
all: clean build run

.PHONY: build
build:
	xvlog -f xvlog_cmd.txt
	xelab -debug wave $(TOP_MODULE) glbl -s $(TOP_MODULE) -L unisims_ver -L unimacro_ver -L secureip

.PHONY: run
run:
	xsim $(TOP_MODULE) --R


.PHONY: vcd2fst
vcd2fst:
	vcd2fst $(TOP_MODULE).vcd $(TOP_MODULE).fst

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
	-rm -f *.pgm
	-rm -f *.ppm
	-rm -f axi4_*.txt
