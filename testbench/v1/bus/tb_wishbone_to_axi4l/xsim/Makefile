

TOP_MODULE = tb_sim

.PHONY: all
all: clean build run

.PHONY: build
build:
	xvlog -f xvlog_cmd.txt
	xelab -debug wave $(TOP_MODULE) -s $(TOP_MODULE)

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
	-rm -f $(TOP_MODULE).wdb $(TOP_MODULE).vcd $(TOP_MODULE).fst

.PHONY: vcd2fst
vcd2fst: $(TOP_MODULE).fst

$(TOP_MODULE).vcd: build run

$(TOP_MODULE).fst: $(TOP_MODULE).vcd
	vcd2fst -v $(TOP_MODULE).vcd -f $(TOP_MODULE).fst

.PHONY: gtkwave
gtkwave: $(TOP_MODULE).fst
	gtkwave $(TOP_MODULE).fst
