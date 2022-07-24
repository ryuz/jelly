
#include <verilated.h>
#include "Vsim_top.h"
#include "jelly/simulator/Axi4sVideoPybind11.h"


namespace jsim = jelly::simulator;

using BaseModel = jsim::Axi4sVideoPybind11<Vsim_top, std::uint8_t, std::int16_t, 8, 16, 1, 3>;

class Sobel : public BaseModel {
public:
    Sobel(int width, int height) : BaseModel(width, height, "sobel") {}
};


PYBIND11_MODULE(sobel, p)
{
    pybind11::class_<Sobel>(p, "Sobel")
            .def(pybind11::init<int, int>())
            .def("set_image_size", &Sobel::SetImageSize)
            .def("run",            &Sobel::Run)
            .def("write_reg",      &Sobel::WriteReg)
            .def("wait_bus",       &Sobel::WaitBus)
            .def("write_stream",   &Sobel::WriteStream)
            .def("write_que_size", &Sobel::GetWriteQueSize)
            .def("read_stream",    &Sobel::ReadStream)
            .def("read_que_size",  &Sobel::GetReadQueSize)
            .def("write_image",    &Sobel::WriteImage)
            .def("read_image",     &Sobel::ReadImage)
            ;
}


// end of file
