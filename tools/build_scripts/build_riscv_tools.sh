#! /bin/bash

TOOLCHAIN_VERSION=2022.06.10
INSTALL_PREFIX=/opt/riscv-gnu-toolchain/riscv-gnu-toolchain-$TOOLCHAIN_VERSION

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR


if [ ! -d riscv-gnu-toolchain ]; then
    git clone -b $TOOLCHAIN_VERSION --recurse-submodules --depth 1 --shallow-submodules https://github.com/riscv/riscv-gnu-toolchain riscv-gnu-toolchain-$TOOLCHAIN_VERSION
#   git clone -b $TOOLCHAIN_VERSION --recurse-submodules https://github.com/riscv/riscv-gnu-toolchain  riscv-gnu-toolchain-$TOOLCHAIN_VERSION
fi

cd riscv-gnu-toolchain-$TOOLCHAIN_VERSION

./configure --prefix=/opt/riscv --enable-multilib

make -j2
sudo make install

cd ..

# rm -fr riscv-gnu-toolchain-$TOOLCHAIN_VERSION
