#!/bin/bash -e
cd `dirname $0`

if [ ! -d bootgen ]; then
    git clone https://github.com/Xilinx/bootgen bootgen
fi

if [ ! -d opencv3 ]; then
    echo opencv3
    git clone -b 3.4.18 --depth 1 https://github.com/opencv/opencv opencv3
fi

if [ ! -d opencv3_contrib ]; then
    git clone -b 3.4.18 --depth 1 https://github.com/opencv/opencv_contrib opencv3_contrib
fi

if [ ! -d opencv4 ]; then
    git clone -b 4.4.0 --depth 1 https://github.com/opencv/opencv opencv4
fi

if [ ! -d opencv4_contrib ]; then
    git clone -b 4.4.0 --depth 1 https://github.com/opencv/opencv_contrib opencv4_contrib
fi

if [ ! -d riscv-gnu-toolchain ]; then
#   git clone -b 2022.06.10 --recurse-submodules --depth 1 --shallow-submodules https://github.com/riscv/riscv-gnu-toolchain 
    git clone -b 2022.06.10 --recurse-submodules https://github.com/riscv/riscv-gnu-toolchain 
fi

if [ ! -d grpc ]; then
    git clone -b v1.46.3 --recurse-submodules --depth 1 --shallow-submodules https://github.com/grpc/grpc
fi
