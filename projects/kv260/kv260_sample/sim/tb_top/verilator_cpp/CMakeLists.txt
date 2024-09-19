
cmake_minimum_required(VERSION 3.16)

project(tb_verilator)

find_package(verilator 4.218 REQUIRED HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
    message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()


# vivado version
execute_process (
    COMMAND vivado -version
    OUTPUT_VARIABLE VIVADO_VERSION_TEXT
)
string(REGEX MATCH [[v[0-9]+\.[0-9]+]] VIVADO_VERSION ${VIVADO_VERSION_TEXT})
string(SUBSTRING ${VIVADO_VERSION} 1 6 VIVADO_VERSION)
string(SUBSTRING ${VIVADO_VERSION} 0 4 VIVADO_VERSION_MAJOR)
string(SUBSTRING ${VIVADO_VERSION} 5 1 VIVADO_VERSION_MINOR)
message("VIVADO_VERSION: ${VIVADO_VERSION}")

add_executable(tb_verilator ./tb_verilator.cpp)

target_include_directories(tb_verilator PUBLIC "../../../../../../include")
set(CMAKE_CXX_FLAGS "-O3 -std=c++17")
target_link_libraries(tb_verilator PUBLIC "-pthread") 

set(RTL_SRCS
    ../tb_main.sv
)

verilate(tb_verilator
#    COVERAGE
    TRACE
    INCLUDE_DIRS "."
    VERILATOR_ARGS -f verilator_cmd.txt -O3
    SOURCES ${RTL_SRCS})
