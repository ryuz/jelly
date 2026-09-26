#! /bin/bash

TOOLCHAIN_VERSION=2026.08.27
INSTALL_PREFIX=$HOME/.opt/riscv-gnu-toolchain/riscv-gnu-toolchain-$TOOLCHAIN_VERSION

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR


if [ ! -d riscv-gnu-toolchain ]; then
    git clone -b $TOOLCHAIN_VERSION --recurse-submodules --depth 1 --shallow-submodules https://github.com/riscv/riscv-gnu-toolchain riscv-gnu-toolchain-$TOOLCHAIN_VERSION
#   git clone -b $TOOLCHAIN_VERSION --recurse-submodules https://github.com/riscv/riscv-gnu-toolchain  riscv-gnu-toolchain-$TOOLCHAIN_VERSION
fi

cd riscv-gnu-toolchain-$TOOLCHAIN_VERSION

./configure --prefix=$INSTALL_PREFIX --enable-multilib
#./configure --prefix=$INSTALL_PREFIX

make -j4
make install

cd ..

# rm -fr riscv-gnu-toolchain-$TOOLCHAIN_VERSION
