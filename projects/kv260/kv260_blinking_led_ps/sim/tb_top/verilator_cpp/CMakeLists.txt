
cmake_minimum_required(VERSION 3.16)

project(tb_verilator)

find_package(verilator 4.218 REQUIRED HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
    message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

add_executable(tb_verilator ./tb_verilator.cpp)

target_include_directories(tb_verilator PUBLIC "../../../../../../include")
set(CMAKE_CXX_FLAGS "-O3 -std=c++17")
target_link_libraries(tb_verilator PUBLIC "-pthread") 

set(RTL_SRCS
    ../tb_main.sv
)

verilate(tb_verilator
    COVERAGE
    TRACE
    INCLUDE_DIRS "."
    VERILATOR_ARGS -f verilator_cmd.txt -O3
    SOURCES ${RTL_SRCS})
