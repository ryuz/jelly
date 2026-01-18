#!/bin/bash

# build
rm -f fclkcfg-*.deb
sudo rm -fr fclkcfg-kmod-dpkg
git clone --recursive --depth=1 -b v1.9.0 https://github.com/ikwzm/fclkcfg-kmod-dpkg
cd fclkcfg-kmod-dpkg
sudo debian/rules binary
cd ..
sudo chown $USER:$USER fclkcfg-*.deb

# install
sudo dpkg -i fclkcfg-*.deb

# clean
sudo rm -fr fclkcfg-kmod-dpkg
