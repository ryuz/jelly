
#include <verilated.h>
#include "Vsim_top.h"
#include "jelly/simulator/Axi4sVideoPybind11.h"

JSIM_DEFINE_AXI4S_VIDEO_PYBIND11(Filter2d, filter2d, Vsim_top, std::uint8_t, std::uint8_t, 8, 8, 3, 3)


// end of file
