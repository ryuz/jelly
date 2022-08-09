

# cmake のフラグ
CMAKE_FLAGS = 

# data ディレクトリ
DATA_DIR = ../../../data

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


all: build

.PHONY : build
build:
	mkdir -p build && cd build && cmake $(CMAKE_FLAGS) -Dpybind11_DIR=`pybind11-config --cmakedir` ..
	cmake --build build -j

.PHONY : clean
clean:
	rm -rf build

.PHONY : distclean
distclean: clean
	rm -f *.fst *.fst.hier
	rm -f *.vcd
	rm -f *.ppm *.pgm
	rm -f axi*.txt
	rm -f *.so
	rm -f *.dll
	rm -f coverage.dat
	rm -fr annotated

.PHONY : setup_data
setup_data:
	make -C ${DATA_DIR}/images/standard_images color/Mandrill_256x256.ppm

.PHONY : run
run: build setup_data
#	build/demosaic_acpi
	python3 test.py

.PHONY : coverage
coverage:
	verilator_coverage --annotate annotated coverage.dat


