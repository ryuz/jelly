#! /bin/bash

rm -fr openFPGALoader/

git clone https://github.com/trabucayre/openFPGALoader
cd openFPGALoader

mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$HOME/.opt/openFPGALoader

cmake --build

make install

rm -fr openFPGALoader/
