
# 各種ライブラリのビルドスクリプト

必要な事前準備

```
sudo apt update
sudo apt install -y build-essential cmake git
sudo apt install -y autoconf libtool pkg-config
sudo apt install -y libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
sudo apt install -y libeigen3-dev libgtk-3-dev freeglut3-dev libtbb-dev libjpeg-dev libpng++-dev libtiff-dev libopenexr-dev libwebp-dev libhdf5-dev
sudo apt install -y libtbb-dev
```

.bashrc に追加する内容

```
# Open-CV3
OPENCV3_PATH=/opt/opencv/opencv-3.4.18
export PATH="$OPENCV3_PATH/bin:$PATH"
export PKG_CONFIG_PATH="$OPENCV3_PATH/lib/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="$OPENCV3_PATH/lib:$LD_LIBRARY_PATH"

# Open-CV4
OPENCV4_PATH=/opt/opencv/opencv-4.4.0
export PATH="$OPENCV4_PATH/bin:$PATH"
export PKG_CONFIG_PATH="$OPENCV4_PATH/lib/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="$OPENCV4_PATH/lib:$LD_LIBRARY_PATH"

# gRPC
GRPC_PATH=/opt/grpc/grpc-1.46.3
export PATH="$GRPC_PATH/bin:$PATH"
export PKG_CONFIG_PATH="$GRPC_PATH/lib/pkgconfig:$PKG_CONFIG_PATH"
```
