

TOP_MODULE=tb_top

.PHONY: all
all: clean build run


.PHONY: build
build:
	xvlog -f xvlog_cmd.txt
	xelab -debug wave $(TOP_MODULE) glbl -s $(TOP_MODULE) -L unisims_ver -L unimacro_ver -L secureip

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

.PHONY: distclean
distclean: clean
	-rm -f *.pgm
	-rm -f *.ppm
	-rm -f $(TOP_MODULE).vcd
	-rm -f $(TOP_MODULE).wdb