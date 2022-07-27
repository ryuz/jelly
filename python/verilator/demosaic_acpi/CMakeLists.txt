
cmake_minimum_required(VERSION 3.16)

set(PRJ_NAME demosaic_acpi)

project(${PRJ_NAME})

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ..)

set(WITH_OPENCV FALSE)

find_package(verilator 4.218 REQUIRED HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
    message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

find_package(pybind11 REQUIRED)
pybind11_add_module(${PRJ_NAME} lib_top.cpp)

target_include_directories(${PRJ_NAME} PUBLIC "../../../include")
set(CMAKE_CXX_FLAGS "-O3 -std=c++17")
target_link_libraries(${PRJ_NAME} PUBLIC "-pthread") 

set(RTL_SRCS
    ./sim_top.sv
)

verilate(${PRJ_NAME}
#    COVERAGE
    TRACE
    INCLUDE_DIRS "."
    VERILATOR_ARGS -f verilator_cmd.txt -Os
    SOURCES ${RTL_SRCS})
