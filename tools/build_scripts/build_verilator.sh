#! /bin/bash

VERILATOR_VERSION=5.036

git clone https://github.com/verilator/verilator.git -b v${VERILATOR_VERSION} verilator-${VERILATOR_VERSION}
cd verilator-${VERILATOR_VERSION}

autoconf
./configure --prefix ${HOME}/.opt/verilator-${VERILATOR_VERSION}
make -j8
make install

