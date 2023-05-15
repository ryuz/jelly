# get vivado version
empty:=
space:= $(empty) $(empty)
VIVADO_VERSIONS := $(subst .,$(space),$(subst v,,$(word 2,$(shell vivado -version))))
VIVADO_VERSION  := $(word 1,$(VIVADO_VERSIONS)).$(word 2,$(VIVADO_VERSIONS))


# setting
TOP_MODULE = tb_sim


# rules
.PHONY: all
all: clean build run

.PHONY: build
build:
	make -C ../../../syn/tcl create
#	xvlog ../../../syn/tcl/kv260_imx219_hls_sample_tcl.gen/sources_1/ip/gaussian_filter_0/hdl/verilog/gaussian_filter_hls_deadlock_detection_unit.v
#	xvlog ../../../syn/tcl/kv260_imx219_hls_sample_tcl.gen/sources_1/ip/laplacian_filter_0/hdl/verilog/laplacian_filter_hls_deadlock_detection_unit.v
	xvlog ../../../syn/tcl/kv260_imx219_hls_sample_tcl.gen/sources_1/ip/gaussian_filter_0/hdl/verilog/*.v
	xvlog ../../../syn/tcl/kv260_imx219_hls_sample_tcl.gen/sources_1/ip/laplacian_filter_0/hdl/verilog/*.v
	xvlog -f xvlog_cmd.txt -i ../../../../../../include
	xelab -debug wave $(TOP_MODULE) glbl -s $(TOP_MODULE) -L unisims_ver -L unimacro_ver -L secureip

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

.PHONY: outputclean
outputclean:
	-rm -f *.vcd
	-rm -f *.wdb
	-rm -f *.pgm
	-rm -f *.ppm
	-rm -f axi4_*.txt

.PHONY: distclean
distclean: clean outputclean
	make -C ../../../syn/tcl distclean
