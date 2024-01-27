#!/bin/bash

rm -f fclkcfg-*.deb
sudo rm -fr fclkcfg-kmod-dpkg
git clone --recursive --depth=1 -b v1.7.2 https://github.com/ikwzm/fclkcfg-kmod-dpkg
cd fclkcfg-kmod-dpkg
sudo debian/rules binary
cd ..
#sudo dpkg -i fclkcfg-*.deb
