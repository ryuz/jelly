
all: build run

.PHONY : build
build:
	mkdir -p build && cd build && cmake ..
	cmake --build build -j

.PHONY : clean
clean:
	rm -rf build

.PHONY : mostlyclean
mostlyclean: clean
	rm -f src_*.pgm
	rm -f img_*.pgm
	rm -f ang_*.ppm


.PHONY : run
run:
	build/tb_verilator

.PHONY : coverage
coverage:
	verilator_coverage --annotate logs/annotated logs/coverage.dat

