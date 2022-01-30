
cmake_minimum_required(VERSION 3.16)

project(tb_verilator)

set(WITH_OPENCV FALSE)

find_package(verilator 4.218 REQUIRED HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
    message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

if ( WITH_OPENCV )
    find_package(OpenCV REQUIRED)
    if (NOT OpenCV_FOUND)
        message(FATAL_ERROR "OpenCV was not found. Either install it")
    endif()
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
#message("VIVADO_VERSION_MAJOR: ${VIVADO_VERSION_MAJOR}")
#message("VIVADO_VERSION_MINOR: ${VIVADO_VERSION_MINOR}")


add_executable(tb_verilator ./tb_verilator.cpp)

target_include_directories(tb_verilator PUBLIC "../../../../../include")
set(CMAKE_CXX_FLAGS "-O3 -std=c++17")
target_link_libraries(tb_verilator PUBLIC "-pthread") 

if ( WITH_OPENCV )
    target_include_directories(tb_verilator PUBLIC ${OpenCV_INCLUDE_DIRS})
    target_link_libraries(tb_verilator PUBLIC ${OpenCV_LIBS})
    add_compile_definitions(WITH_OPENCV2)
endif()


set(RTL_SRCS
    ../tb_sim_main.sv
    ../../stub/design_1.v
    ../../stub/mipi_dphy_cam.v
    # ../../stub/video_filter_0.v
)

if ( ${VIVADO_VERSION} LESS_EQUAL "2019.2" )
    list(APPEND RTL_SRCS ../../../syn/tcl/ultra96v2_imx219_hls_sample_tcl.srcs/sources_1/ip/video_filter_0/hdl/verilog/regslice_core.v)
endif()

verilate(tb_verilator
#    COVERAGE
    TRACE
    INCLUDE_DIRS "."
    VERILATOR_ARGS -f verilator_cmd.txt -Os
    SOURCES ${RTL_SRCS})
