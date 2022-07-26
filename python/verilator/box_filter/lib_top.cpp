
#include <verilated.h>
#include "Vsim_top.h"
#include "jelly/simulator/Axi4sVideoPybind11.h"


namespace jsim = jelly::simulator;

using BaseModel = jsim::Axi4sVideoPybind11<Vsim_top, std::uint8_t, std::uint8_t, 8, 8, 3, 3>;

class BoxFilter : public BaseModel {
public:
    BoxFilter(int width, int height) : BaseModel(width, height, "box_filter") {}
};


PYBIND11_MODULE(box_filter, p)
{
    pybind11::class_<BoxFilter>(p, "BoxFilter")
            .def(pybind11::init<int, int>())
            .def("set_image_size", &BoxFilter::SetImageSize)
            .def("run",            &BoxFilter::Run)
            .def("write_reg",      &BoxFilter::WriteReg)
            .def("write_ireg",     &BoxFilter::WriteIReg)
            .def("wait_bus",       &BoxFilter::WaitBus)
            .def("write_stream",   &BoxFilter::WriteStream)
            .def("write_que_size", &BoxFilter::GetWriteQueSize)
            .def("read_stream",    &BoxFilter::ReadStream)
            .def("read_que_size",  &BoxFilter::GetReadQueSize)
            .def("write_image",    &BoxFilter::WriteImage)
            .def("read_image",     &BoxFilter::ReadImage)
            ;
}


// end of file
