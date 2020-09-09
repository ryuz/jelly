
#include <pybind11/pybind11.h>
#include "jelly/MemAccess.h"
#include "jelly/MmapAccess.h"
#include "jelly/UioAccess.h"
#include "jelly/UdmabufAccess.h"


namespace py = pybind11;


PYBIND11_MODULE(jellypy, m) {
    m.doc() = "JellyPy made by pybind11";

    py::class_<jelly::MemAccess>(m, "MemAccess")
        .def(py::init<>())
        .def("get_size",       &jelly::MemAccess::GetSize)
        .def("get_accessor",   &jelly::MemAccess::GetMemAccess)
        .def("get_accessor8",  &jelly::MemAccess::GetMemAccess8)
        .def("get_accessor16", &jelly::MemAccess::GetMemAccess16)
        .def("get_accessor32", &jelly::MemAccess::GetMemAccess32)
        .def("get_accessor64", &jelly::MemAccess::GetMemAccess64)
        .def("write_reg",      &jelly::MemAccess::WriteReg)
        .def("write_reg8",     &jelly::MemAccess::WriteReg8)
        .def("write_reg16",    &jelly::MemAccess::WriteReg16)
        .def("write_reg32",    &jelly::MemAccess::WriteReg32)
        .def("write_reg64",    &jelly::MemAccess::WriteReg64)
        .def("read_reg",       &jelly::MemAccess::ReadReg)
        .def("read_reg8",      &jelly::MemAccess::ReadReg8)
        .def("read_reg16",     &jelly::MemAccess::ReadReg16)
        .def("read_reg32",     &jelly::MemAccess::ReadReg32)
        .def("read_reg64",     &jelly::MemAccess::ReadReg64)
        .def("write_mem",      &jelly::MemAccess::WriteMem)
        .def("write_mem8",     &jelly::MemAccess::WriteMem8)
        .def("write_mem16",    &jelly::MemAccess::WriteMem16)
        .def("write_mem32",    &jelly::MemAccess::WriteMem32)
        .def("write_mem64",    &jelly::MemAccess::WriteMem64)
        .def("read_mem",       &jelly::MemAccess::ReadMem)
        .def("read_mem8",      &jelly::MemAccess::ReadMem8)
        .def("read_mem16",     &jelly::MemAccess::ReadMem16)
        .def("read_mem32",     &jelly::MemAccess::ReadMem32)
        .def("read_mem64",     &jelly::MemAccess::ReadMem64)
        ;

    py::class_<jelly::MmapAccess, jelly::MemAccess>(m, "MmapAccess")
        .def(py::init<>())
        .def("is_mapped",  &jelly::MmapAccess::IsMapped);

    py::class_<jelly::UioAccess, jelly::MmapAccess>(m, "UioAccess")
        .def(py::init<>())
        .def(py::init<const char*, std::size_t, std::size_t>(),
            py::arg("name"),
            py::arg("size"),
            py::arg("offset") = 0)
        .def(py::init<int, std::size_t, std::size_t>(),
            py::arg("id"),
            py::arg("size"),
            py::arg("offset") = 0)
        .def_static("search_device_id", &jelly::UioAccess::SearchDeviceId) 
        ;

    py::class_<jelly::UdmabufAccess, jelly::MmapAccess>(m, "UdmabufAccess")
        .def(py::init<>())
        .def(py::init<const char*, std::size_t>(),
            py::arg("name"),
            py::arg("offset") = 0)
        .def("get_phys_addr", ((std::intptr_t (jelly::UdmabufAccess::*)())&jelly::UdmabufAccess::GetPhysAddr))
        ;

}

