

# cmake のフラグ
CMAKE_FLAGS = 


# clang があれば使う
ifeq (,$(shell which clang))
WITH_CLANG ?= No
else
WITH_CLANG ?= Yes
endif

# ninja があれば使う
ifeq (,$(shell which ninja))
WITH_NINJA ?= No
else
WITH_NINJA ?= Yes
endif

ifeq ($(WITH_CLANG),Yes)
CMAKE_FLAGS += -C ../clang-cmakeinit.cmake
endif

ifeq ($(WITH_NINJA),Yes)
CMAKE_FLAGS += -GNinja
endif


all: build run

.PHONY : build
build:
	mkdir -p build && cd build && cmake $(CMAKE_FLAGS) ..
	cmake --build build -j

.PHONY : clean
clean:
	rm -rf build

.PHONY : distclean
distclean: clean
	rm -f axi4_*.txt
	rm -f *_log.txt
	rm -f *.ppm *pgm
	rm -f *.vcd *.fst *.fst.hier
	rm -f coverage.dat
	rm -fr annotated

.PHONY : setup_dataset
setup_dataset:
	make -C ../../../../../data/images/windowswallpaper Penguins_640x480.ppm

.PHONY : run
run: setup_dataset
	build/tb_verilator

.PHONY : coverage
coverage:
	verilator_coverage --annotate annotated coverage.dat

