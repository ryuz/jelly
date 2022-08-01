
#include <verilated.h>
#include "Vsim_top.h"
#include "jelly/simulator/Axi4sVideoPybind11.h"

JSIM_DEFINE_AXI4S_VIDEO_PYBIND11(Rgb2Hsv, rgb2hsv, Vsim_top, std::uint16_t, std::int16_t, 10, 10, 3, 3)

// end of file
