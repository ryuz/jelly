

TOP_MODULE=tb_sim

.PHONY: all
all: clean build run


.PHONY: build
build:
	make -C ../../../syn/tcl create
	xvlog -f xvlog_cmd.txt -i ../../../../../include
	xelab -debug wave $(TOP_MODULE) glbl -s $(TOP_MODULE) -L unisims_ver -L unimacro_ver -L secureip -mt off -v 1

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
