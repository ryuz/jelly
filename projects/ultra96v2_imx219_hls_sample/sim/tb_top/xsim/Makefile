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
	xvlog -f xvlog_cmd.txt -i ../../../../../include
ifeq ($(VIVADO_VERSION),2019.2)
	xvlog ../../../syn/tcl/ultra96v2_imx219_hls_sample_tcl.srcs/sources_1/ip/video_filter_0/hdl/verilog/regslice_core.v
endif
ifeq ($(VIVADO_VERSION),2021.2)
	xvlog ../../../syn/tcl/ultra96v2_imx219_hls_sample_tcl.gen/sources_1/ip/video_filter_0/hdl/verilog/video_filter_hls_deadlock_detection_unit.v
endif
	xelab -debug wave $(TOP_MODULE) glbl -s $(TOP_MODULE) -L unisims_ver -L unimacro_ver -L secureip
#	xelab -debug wave $(TOP_MODULE) glbl -s $(TOP_MODULE) -L unisims_ver -L unimacro_ver -L secureip -mt off -v 1

.PHONY: run
run:
	xsim $(TOP_MODULE) -t xsim_run_all.tcl


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
