################################################
# Base
################################################

FROM ubuntu:22.04 as base-builder

LABEL maintainter="ryuz88"

ENV DEBIAN_FRONTEND=noninteractive

# apt-get
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y build-essential cmake git \
 && apt-get install -y autoconf libtool pkg-config \
 && apt-get install -y libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev \
 && apt-get install -y libeigen3-dev libgtk-3-dev freeglut3-dev libtbb-dev libjpeg-dev libpng++-dev libtiff-dev libopenexr-dev libwebp-dev libhdf5-dev \
 && apt-get install -y autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev \
 && apt-get install -y libtbb-dev \
 && apt-get install -y device-tree-compiler libssl-dev \
 && apt-get install -y gcc-arm-none-eabi \
 && apt-get install -y libnewlib-arm-none-eabi \
 && apt-get install -y openssh-server xauth \
 && apt-get install -y python3-pip \
 && apt-get install -y sudo



################################################
# OpenCV3
################################################

FROM base-builder as opencv3-builder

COPY ./files/opencv3         /opencv3
COPY ./files/opencv3_contrib /opencv3_contrib

RUN mkdir opencv3/build
WORKDIR /opencv3/build
RUN cmake .. \
    -DOPENCV_EXTRA_MODULES_PATH=/opencv3_contrib/modules \
    -DOPENCV_GENERATE_PKGCONFIG=ON \
    -DCMAKE_INSTALL_PREFIX=/opt/opencv3
RUN make -j8
RUN make install
WORKDIR /
# RUN rm -fr opencv3 opencv3_contrib



################################################
# OpenCV4
################################################

FROM base-builder as opencv4-builder

COPY ./files/opencv4         /opencv4
COPY ./files/opencv4_contrib /opencv4_contrib

RUN mkdir opencv4/build
WORKDIR /opencv4/build
RUN cmake .. \
    -DOPENCV_EXTRA_MODULES_PATH=/opencv4_contrib/modules \
    -DOPENCV_GENERATE_PKGCONFIG=ON \
    -DCMAKE_INSTALL_PREFIX=/opt/opencv4
RUN make -j8
RUN make install
WORKDIR /
# RUN rm -fr opencv3 opencv3_contrib



################################################
# risc-v
################################################

FROM base-builder as riscv-builder

# risc-v
COPY ./files/riscv-gnu-toolchain /riscv-gnu-toolchain
WORKDIR /riscv-gnu-toolchain
RUN ./configure --prefix=/opt/riscv --enable-multilib
RUN make -j4
WORKDIR /
#RUN rm -fr riscv-gnu-toolchain



################################################
# gRPC
################################################

FROM base-builder as grpc-builder

# gRPC
COPY ./files/grpc /grpc
RUN mkdir grpc/cmake/build
WORKDIR /grpc/cmake/build
RUN cmake -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/opt/grpc ../..
RUN make -j8
RUN make install
WORKDIR /
#RUN rm -fr grpc



################################################
# Xilinx tools
################################################

FROM base-builder as xilinx-builder

# bootgen
COPY ./files/bootgen /bootgen
WORKDIR /bootgen
RUN make
RUN cp bootgen /usr/local/bin
WORKDIR /
#RUN rm -fr bootgen



################################################
# Target Image
################################################

FROM base-builder

LABEL maintainter="ryuz88"

# python 
RUN pip install numpy Flask \
 && pip install opencv-contrib-python

# copy
COPY --from=grpc-builder    /opt/grpc        /opt/grpc
COPY --from=opencv4-builder /opt/opencv4     /opt/opencv4
COPY --from=opencv3-builder /opt/opencv3     /opt/opencv3
COPY --from=riscv-builder   /opt/riscv       /opt/riscv
COPY --from=xilinx-builder  /bootgen/bootgen /usr/local/bin

# sshd
RUN mkdir /var/run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
RUN sed -i 's/#Port 22/Port 20022/' /etc/ssh/sshd_config
RUN sed -i 's/#X11DisplayOffset 10/X11DisplayOffset 10/' /etc/ssh/sshd_config
RUN sed -i 's/#X11UseLocalhost yes/X11UseLocalhost no/' /etc/ssh/sshd_config
EXPOSE 20022

# sudo
RUN echo 'root:admin' | chpasswd

# entrypoint
COPY ./files/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
