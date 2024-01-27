#!/bin/bash

rm -f u-dma-buf-*.deb
sudo rm -fr u-dma-buf-kmod-dpkg
git clone --recursive --depth=1 -b v4.5.2 https://github.com/ikwzm/u-dma-buf-kmod-dpkg
cd u-dma-buf-kmod-dpkg
sudo debian/rules binary
cd ..
#sudo dpkg -i u-dma-buf-*.deb
