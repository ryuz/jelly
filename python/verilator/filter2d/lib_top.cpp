
#include <verilated.h>
#include "Vsim_top.h"
#include "jelly/simulator/Axi4sVideoPybind11.h"


namespace jsim = jelly::simulator;

using BaseModel = jsim::Axi4sVideoPybind11<Vsim_top, std::uint8_t, std::uint8_t, 8, 8, 3, 3>;

class Filter2d : public BaseModel {
public:
    Filter2d(int width, int height) : BaseModel(width, height, "box_filter") {}
};


PYBIND11_MODULE(filter2d, p)
{
    pybind11::class_<Filter2d>(p, "Filter2d")
            .def(pybind11::init<int, int>())
            .def("set_image_size", &Filter2d::SetImageSize)
            .def("run",            &Filter2d::Run)
            .def("write_reg",      &Filter2d::WriteReg)
            .def("write_ireg",     &Filter2d::WriteIReg)
            .def("wait_bus",       &Filter2d::WaitBus)
            .def("write_stream",   &Filter2d::WriteStream)
            .def("write_que_size", &Filter2d::GetWriteQueSize)
            .def("read_stream",    &Filter2d::ReadStream)
            .def("read_que_size",  &Filter2d::GetReadQueSize)
            .def("write_image",    &Filter2d::WriteImage)
            .def("read_image",     &Filter2d::ReadImage)
            ;
}


// end of file
