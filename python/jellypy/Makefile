
.PHONY: all
all:
	g++ -O3 -I../../include -Wall -shared -std=c++11 -fPIC `python3 -m pybind11 --includes` accessor.cpp -o accessor`python3-config --extension-suffix`
	g++ -O3 -I../../include -Wall -shared -std=c++11 -fPIC `python3 -m pybind11 --includes` imx219.cpp   -o imx219`python3-config --extension-suffix`

