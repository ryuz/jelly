

# setting
TOP_MODULE = tb_data_ff

all: build run

.PHONY : build
build:
	verilator ../$(TOP_MODULE).sv --top $(TOP_MODULE) -f verilator_cmd.txt 

.PHONY : clean
clean:
	rm -rf obj_dir

.PHONY : distclean
distclean: clean
	rm -f *.fst *.vcd
	rm -f *.ppm *.pgm
	rm -f axi*.txt
	rm -f coverage.dat
	rm -fr annotated


.PHONY : run
run:
	./obj_dir/V$(TOP_MODULE)

.PHONY : coverage
coverage:
	verilator_coverage --annotate annotated coverage.dat


