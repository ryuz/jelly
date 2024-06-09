

all: build run

.PHONY : build
build:
	verilator -f verilator_cmd.txt 

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
	./obj_dir/Vtb_pipeline_insert_ff

.PHONY : coverage
coverage:
	verilator_coverage --annotate annotated coverage.dat


