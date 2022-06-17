
################################################
# gRPC
################################################

FROM ubuntu:20.04 as grpc-builder

LABEL maintainter="ryuz88"

ENV DEBIAN_FRONTEND=noninteractive

# apt-get
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get install -y build-essential cmake git
RUN apt-get install -y autoconf libtool pkg-config

# gRPC
#RUN git clone --recurse-submodules -b v1.34.1 --depth 1 --shallow-submodules https://github.com/grpc/grpc
RUN git clone --recurse-submodules -b v1.46.3 --depth 1 --shallow-submodules https://github.com/grpc/grpc
RUN mkdir grpc/cmake/build
WORKDIR /grpc/cmake/build
RUN cmake -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/opt/grpc ../..
RUN make -j8
RUN make install
WORKDIR /
#RUN rm -fr grpc


################################################
# OpenCV
################################################

FROM ubuntu:20.04 as opencv-builder

LABEL maintainter="ryuz88"

ENV DEBIAN_FRONTEND=noninteractive

# apt-get
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get install -y build-essential cmake git 
RUN apt-get install -y libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
RUN apt-get install -y wget unzip

RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/4.4.0.zip
RUN unzip opencv.zip
RUN wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.4.0.zip
RUN unzip opencv_contrib

RUN mkdir opencv-4.4.0/build
WORKDIR /opencv-4.4.0/build
# RUN cmake .. -DCMAKE_INSTALL_PREFIX=/opt/opencv
RUN cmake .. -DOPENCV_EXTRA_MODULES_PATH=/opencv_contrib-4.4.0/modules -DCMAKE_INSTALL_PREFIX=/opt/opencv
RUN make -j8
RUN make install
WORKDIR /
# RUN rm opencv.zip opencv_contrib.zip
# RUN rm -fr opencv-4.4.0

################################################
# risc-v
################################################

FROM ubuntu:20.04 as riscv-builder

LABEL maintainter="ryuz88"

ENV DEBIAN_FRONTEND=noninteractive

# apt-get
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get install -y build-essential cmake git
RUN apt-get install -y autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev

# risc-v
RUN git clone https://github.com/riscv/riscv-gnu-toolchain
WORKDIR /riscv-gnu-toolchain
RUN ./configure --prefix=/opt/riscv --enable-multilib
RUN make -j8
WORKDIR /
#RUN rm -fr riscv-gnu-toolchain


################################################
# Xilinx tools
################################################

FROM ubuntu:20.04 as xilinx-builder

LABEL maintainter="ryuz88"

ENV DEBIAN_FRONTEND=noninteractive

# apt-get
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get install -y build-essential cmake git 
RUN apt-get install -y device-tree-compiler libssl-dev

# bootgen
RUN git clone https://github.com/Xilinx/bootgen
WORKDIR /bootgen
RUN make
RUN cp bootgen /usr/local/bin
WORKDIR /
#RUN rm -fr bootgen


################################################
# Target Image
################################################

FROM ubuntu:20.04

LABEL maintainter="ryuz88"

ENV DEBIAN_FRONTEND=noninteractive

# apt-get
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get install -y build-essential cmake git

RUN apt-get install -y autoconf libtool pkg-config
RUN apt-get install -y libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
RUN apt-get install -y device-tree-compiler libssl-dev

# for RPU
RUN apt-get install -y gcc-arm-none-eabi
RUN apt-get install -y libnewlib-arm-none-eabi

# python 
RUN apt install -y python3-pip
RUN pip install numpy Flask

# xauth
RUN apt-get install -y xauth

# sshd
RUN apt-get install -y openssh-server xauth
RUN mkdir /var/run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
RUN sed -i 's/#Port 22/Port 20022/' /etc/ssh/sshd_config
RUN sed -i 's/#X11DisplayOffset 10/X11DisplayOffset 10/' /etc/ssh/sshd_config
RUN sed -i 's/#X11UseLocalhost yes/X11UseLocalhost no/' /etc/ssh/sshd_config
EXPOSE 20022

# sudo
RUN apt-get install -y sudo
RUN echo 'root:admin' | chpasswd

# copy
COPY --from=grpc-builder   /opt/grpc   /opt/grpc
COPY --from=opencv-builder /opt/opencv /opt/opencv
COPY --from=riscv-builder  /opt/riscv  /opt/riscv

# entrypoint
COPY ./files/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
