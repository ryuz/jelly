

#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <pybind11/operators.h>


#define __JELLY__PYBIND11__


#include "jelly/Imx219Control.h"


namespace py = pybind11;

std::string GetVersion(void)   { return "0.1"; }
std::string GetBuildDate(void) { return __DATE__; }
std::string GetBuildTime(void) { return __TIME__; }


PYBIND11_MODULE(imx219, m) {
    m.doc() = "JellyPy made by pybind11";

    m.def("get_version",    &GetVersion);
    m.def("get_build_date", &GetBuildDate);
    m.def("get_build_time", &GetBuildTime);

    py::class_< jelly::Imx219ControlI2c >(m, "Imx219ControlI2c")
        .def(py::init<>())
        .def(py::init<bool>())
        .def("open",                &jelly::Imx219ControlI2c::Open,
            py::arg("fname"),
            py::arg("dev"))
        .def("close",               &jelly::Imx219ControlI2c::Close)
        .def("is_opend",            &jelly::Imx219ControlI2c::IsOpend)
        .def("get_model_id",        &jelly::Imx219ControlI2c::GetModelId)
        .def("reset",               &jelly::Imx219ControlI2c::Reset)
        .def("start",               &jelly::Imx219ControlI2c::Start)
        .def("stop",                &jelly::Imx219ControlI2c::Stop)
        .def("set_pixel_clock",     &jelly::Imx219ControlI2c::SetPixelClock)
        .def("get_pixel_clock",     &jelly::Imx219ControlI2c::GetPixelClock)
        .def("set_gain",            &jelly::Imx219ControlI2c::SetGain)
        .def("get_gain",            &jelly::Imx219ControlI2c::GetGain)
        .def("set_digital_gain",    &jelly::Imx219ControlI2c::SetDigitalGain)
        .def("get_digital_gain",    &jelly::Imx219ControlI2c::GetDigitalGain)
        .def("set_frame_rate",      &jelly::Imx219ControlI2c::SetFrameRate)
        .def("get_frame_rate",      &jelly::Imx219ControlI2c::GetFrameRate)
        .def("set_exposure_time",   &jelly::Imx219ControlI2c::SetExposureTime)
        .def("get_exposure_time",   &jelly::Imx219ControlI2c::GetExposureTime)
        .def("get_sensor_width",    &jelly::Imx219ControlI2c::GetSensorWidth)
        .def("get_sensor_height",   &jelly::Imx219ControlI2c::GetSensorHeight)
        .def("get_sensor_center_x", &jelly::Imx219ControlI2c::GetSensorCenterX)
        .def("get_sensor_center_y", &jelly::Imx219ControlI2c::GetSensorCenterY)
        .def("set_aoi",             &jelly::Imx219ControlI2c::SetAoi,
            py::arg("width"),
            py::arg("height"),
            py::arg("x")=-1,
            py::arg("y")=-1,
            py::arg("binning_h")=false,
            py::arg("binning_v")=false)
        .def("set_aoi_size",        &jelly::Imx219ControlI2c::SetAoiSize,
            py::arg("width"),
            py::arg("height"))
        .def("set_aoi_position",    &jelly::Imx219ControlI2c::SetAoiPosition,
            py::arg("x"),
            py::arg("y"))
        .def("get_aoi_width",       &jelly::Imx219ControlI2c::GetAoiWidth)
        .def("get_aoi_height",      &jelly::Imx219ControlI2c::GetAoiHeight)
        .def("get_aoi_x",           &jelly::Imx219ControlI2c::GetAoiX)
        .def("get_aoi_y",           &jelly::Imx219ControlI2c::GetAoiY)
        .def("set_flip",            &jelly::Imx219ControlI2c::SetFlip,
            py::arg("flip_h"),
            py::arg("flip_v"))
        .def("get_flip_h",          &jelly::Imx219ControlI2c::GetFlipH)
        .def("get_flip_v",          &jelly::Imx219ControlI2c::GetFlipV)
        ;
}

