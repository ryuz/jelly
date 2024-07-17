

TOP_MODULE=tb_sim

.PHONY: all
all: clean build run


.PHONY: build
build:
	make -C ../rust_app
	xvlog -f xvlog_cmd.txt
	xelab -debug wave $(TOP_MODULE) -s $(TOP_MODULE)

.PHONY: run
run:
	xsim $(TOP_MODULE) -t xsim_run_all.tcl
#	diff <(head -n 5000 jfive_exe_log.txt) <(head -n 5000 jfive_exe_log_exp.txt)

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