#!/bin/bash

# build
rm -fr uiomem
git clone -b v1.0.0-alpha.4 https://github.com/ikwzm/uiomem.git
cd uiomem
make

# install
sudo cp uiomem.ko /lib/modules/$(uname -r)/ikwzm
sudo depmod -a

# clean
cd ..
rm -fr uiomem
