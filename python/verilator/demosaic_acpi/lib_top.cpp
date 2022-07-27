
#include <verilated.h>
#include "Vsim_top.h"
#include "jelly/simulator/Axi4sVideoPybind11.h"


JSIM_DEFINE_AXI4S_VIDEO_PYBIND11(DemosaicAcpi, demosaic_acpi, Vsim_top, std::uint16_t, std::uint16_t, 10, 10, 1, 3)


// end of file
