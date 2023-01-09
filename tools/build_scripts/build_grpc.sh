#! /bin/bash

GRPC_VERSION=1.46.3
INSTALL_PREFIX=/opt/grpc/grpc-$GRPC_VERSION

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR


if [ ! -d grpc-$GRPC_VERSION ]; then
    git clone -b v$GRPC_VERSION --recurse-submodules --depth 1 --shallow-submodules https://github.com/grpc/grpc grpc-$GRPC_VERSION
fi

cd grpc-$GRPC_VERSION

mkdir build
cd    build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DgRPC_INSTALL=ON \
    -DgRPC_BUILD_TESTS=OFF

make -j2
sudo make install

cd ../..

# rm -fr grpc-$GRPC_VERSION
