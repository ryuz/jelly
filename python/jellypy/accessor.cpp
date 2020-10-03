

#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <pybind11/operators.h>


#define __JELLY__PYBIND11__

#include "jelly/MemAccessor.h"
#include "jelly/MmapAccessor.h"
#include "jelly/UioAccessor.h"
#include "jelly/UdmabufAccessor.h"
#include "jelly/GpioAccessor.h"


namespace py = pybind11;

std::string GetVersion(void)   { return "0.1"; }
std::string GetBuildDate(void) { return __DATE__; }
std::string GetBuildTime(void) { return __TIME__; }


PYBIND11_MODULE(accessor, m) {
    m.doc() = "JellyPy made by pybind11";

    m.def("get_version",    &GetVersion);
    m.def("get_build_date", &GetBuildDate);
    m.def("get_build_time", &GetBuildTime);

    
    py::class_< jelly::MemAccessor >(m, "MemAccessor")
        .def(py::init<>())
        .def("get_size",          &jelly::MemAccessor::GetSize)
        .def("get_accessor",      &jelly::MemAccessor::GetAccessor,
            py::arg("addr"),
            py::arg("reg_unit")=0)
        .def("get_accessor_reg",  &jelly::MemAccessor::GetAccessorReg,
            py::arg("addr"),
            py::arg("reg_unit")=0)
        .def("set_reg_addr_unit", &jelly::MemAccessor::SetRegAddrUnit)
        .def("get_reg_addr_unit", &jelly::MemAccessor::GetRegAddrUnit)
        .def("write_reg",         &jelly::MemAccessor::WriteReg)
        .def("write_reg8",        &jelly::MemAccessor::WriteReg8)
        .def("write_reg16",       &jelly::MemAccessor::WriteReg16)
        .def("write_reg32",       &jelly::MemAccessor::WriteReg32)
        .def("write_reg64",       &jelly::MemAccessor::WriteReg64)
        .def("read_reg",          &jelly::MemAccessor::ReadReg)
        .def("read_reg8",         &jelly::MemAccessor::ReadReg8)
        .def("read_reg16",        &jelly::MemAccessor::ReadReg16)
        .def("read_reg32",        &jelly::MemAccessor::ReadReg32)
        .def("read_reg64",        &jelly::MemAccessor::ReadReg64)
        .def("write_mem",         &jelly::MemAccessor::WriteMem)
        .def("write_mem8",        &jelly::MemAccessor::WriteMem8)
        .def("write_mem16",       &jelly::MemAccessor::WriteMem16)
        .def("write_mem32",       &jelly::MemAccessor::WriteMem32)
        .def("write_mem64",       &jelly::MemAccessor::WriteMem64)
        .def("read_mem",          &jelly::MemAccessor::ReadMem)
        .def("read_mem8",         &jelly::MemAccessor::ReadMem8)
        .def("read_mem16",        &jelly::MemAccessor::ReadMem16)
        .def("read_mem32",        &jelly::MemAccessor::ReadMem32)
        .def("read_mem64",        &jelly::MemAccessor::ReadMem64)
        .def("get_array_uint8",   &jelly::MemAccessor::GetArray_<std::uint8_t>,
            py::arg("shape"),
            py::arg("offset") = 0)
        .def("get_array_int8",   &jelly::MemAccessor::GetArray_<std::int8_t>,
            py::arg("shape"),
            py::arg("offset") = 0)
        .def("get_array_uint16", &jelly::MemAccessor::GetArray_<std::int16_t>,
            py::arg("shape"),
            py::arg("offset") = 0)
        .def("get_array_int16",  &jelly::MemAccessor::GetArray_<std::uint16_t>,
            py::arg("shape"),
            py::arg("offset") = 0)
        .def("get_array_uint32", &jelly::MemAccessor::GetArray_<std::uint32_t>,
            py::arg("shape"),
            py::arg("offset") = 0)
        .def("get_array_int32",  &jelly::MemAccessor::GetArray_<std::int32_t>,
            py::arg("shape"),
            py::arg("offset") = 0)
        .def("get_array_uint64", &jelly::MemAccessor::GetArray_<std::uint64_t>,
            py::arg("shape"),
            py::arg("offset") = 0)
        .def("get_array_int64",  &jelly::MemAccessor::GetArray_<std::int64_t>,
            py::arg("shape"),
            py::arg("offset") = 0)
        ;

    py::class_< jelly::MmapAccessor, jelly::MemAccessor>(m, "MmapAccessor")
        .def(py::init<>())
        .def("is_mapped",  &jelly::MmapAccessor::IsMapped)
        ;

    py::class_< jelly::UioAccessor, jelly::MmapAccessor >(m, "UioAccessor")
        .def(py::init<>())
        .def(py::init<const char*, std::size_t, std::size_t>(),
            py::arg("name"),
            py::arg("size"),
            py::arg("offset") = 0)
        .def(py::init<int, std::size_t, std::size_t>(),
            py::arg("id"),
            py::arg("size"),
            py::arg("offset") = 0)
        .def_static("search_device_id", &jelly::UioAccessor::SearchDeviceId) 
        ;

    py::class_< jelly::UdmabufAccessor, jelly::MmapAccessor >(m, "UdmabufAccessor")
        .def(py::init<>())
        .def(py::init<const char*, std::size_t>(),
            py::arg("name"),
            py::arg("offset") = 0)
        .def("get_phys_addr", ((std::intptr_t (jelly::UdmabufAccessor::*)())&jelly::UdmabufAccessor::GetPhysAddr))
        ;


    py::class_< jelly::GpioAccessor >(m, "GpioAccessor")
        .def(py::init<int, bool>(),
            py::arg("gpio"),
            py::arg("auto_export") = true)
        .def("exists",               &jelly::GpioAccessor::Exists)
        .def("export",               &jelly::GpioAccessor::Export)
        .def("unexport",             &jelly::GpioAccessor::Unexport)
        .def("set_direction",        &jelly::GpioAccessor::SetDirection,
            py::arg("dir_output"))
        .def("set_value",            &jelly::GpioAccessor::SetValue,
            py::arg("value"))
        .def("get_value",            &jelly::GpioAccessor::GetValue)
        ;

}

