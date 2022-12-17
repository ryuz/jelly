#! /bin/bash

OPENCV_VERSION=3.4.18
INSTALL_PREFIX=/opt/opencv/opencv-$OPENCV_VERSION

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

if [ ! -d opencv-$OPENCV_VERSION ]; then
    git clone -b $OPENCV_VERSION --depth 1 https://github.com/opencv/opencv opencv-$OPENCV_VERSION
fi

if [ ! -d opencv_contrib-$OPENCV_VERSION ]; then
    git clone -b $OPENCV_VERSION --depth 1 https://github.com/opencv/opencv_contrib opencv_contrib-$OPENCV_VERSION
fi

cd opencv-$OPENCV_VERSION
mkdir build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DOPENCV_GENERATE_PKGCONFIG=ON \
    -DOPENCV_EXTRA_MODULES_PATH=$SCRIPT_DIR/opencv_contrib-$OPENCV_VERSION/modules

make -j2
sudo make install
cd ../..

# rm -fr opencv4-$OPENCV_VERSION opencv4_contrib-$OPENCV_VERSION
