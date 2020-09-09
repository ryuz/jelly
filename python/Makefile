


.PHONY: all
all:
	g++ -O3 -I../include -Wall -shared -std=c++11 -fPIC `python3 -m pybind11 --includes` jellypy.cpp -o jellypy`python3-config --extension-suffix`

