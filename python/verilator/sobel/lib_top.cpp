
#include <verilated.h>
#include "Vsim_top.h"
#include "jelly/simulator/Axi4sVideoPybind11.h"

JSIM_DEFINE_AXI4S_VIDEO_PYBIND11(Sobel, sobel, Vsim_top, std::uint8_t, std::int16_t, 8, 16, 1, 3)


// end of file
