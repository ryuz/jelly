################################################
# Base
################################################

FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04 AS base-builder

LABEL maintainter="ryuz88"
LABEL org.opencontainers.image.source="https://github.com/ryuz/jelly"

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
# Verilator
################################################

FROM base-builder AS verilator-builder

ARG VERILATOR_VERSION=5.038

RUN git clone https://github.com/verilator/verilator.git -b v${VERILATOR_VERSION} verilator-${VERILATOR_VERSION}

RUN apt-get update \
 && apt-get install -y autoconf flex bison help2man

WORKDIR /verilator-${VERILATOR_VERSION}

RUN autoconf \
 && ./configure --prefix ${HOME}/.opt/verilator-${VERILATOR_VERSION} \
 && make -j \
 && make install



################################################
# RISC-V
################################################

FROM base-builder AS riscv-builder

# risc-v
#COPY ./files/riscv-gnu-toolchain /riscv-gnu-toolchain
RUN git clone -b 2025.09.28 https://github.com/riscv/riscv-gnu-toolchain
WORKDIR /riscv-gnu-toolchain
RUN ./configure --prefix=/opt/riscv --enable-multilib
RUN make
WORKDIR /



################################################
# Xilinx tools
################################################

FROM base-builder AS xilinx-builder

# bootgen
#COPY ./files/bootgen /bootgen
RUN git clone https://github.com/Xilinx/bootgen bootgen
WORKDIR /bootgen
RUN make
RUN cp bootgen /usr/local/bin
WORKDIR /
#RUN rm -fr bootgen



################################################
# Target Image
################################################

FROM base-builder

USER root

# copy
COPY --from=riscv-builder   /opt/riscv       /opt/riscv
COPY --from=xilinx-builder  /usr/local/bin   /usr/local/bin

# arm
RUN dpkg --add-architecture arm64 \
 && dpkg --add-architecture armhf \
 && release=$(. /etc/os-release && echo "$UBUNTU_CODENAME") \
 && mv /etc/apt/sources.list /etc/apt/sources.list.amd64 \
 && printf "deb [arch=amd64] http://archive.ubuntu.com/ubuntu %s main universe multiverse restricted\n" "$release" > /etc/apt/sources.list \
 && printf "deb [arch=amd64] http://archive.ubuntu.com/ubuntu %s-updates main universe multiverse restricted\n" "$release" >> /etc/apt/sources.list \
 && printf "deb [arch=amd64] http://archive.ubuntu.com/ubuntu %s-backports main universe multiverse restricted\n" "$release" >> /etc/apt/sources.list \
 && printf "deb [arch=amd64] http://security.ubuntu.com/ubuntu %s-security main universe multiverse restricted\n" "$release" >> /etc/apt/sources.list \
 && rm -f /etc/apt/sources.list.d/* \
 && printf "deb [arch=arm64,armhf] http://ports.ubuntu.com/ubuntu-ports %s main universe multiverse restricted\n" "$release" > /etc/apt/sources.list.d/arm-ports.list \
 && printf "deb [arch=arm64,armhf] http://ports.ubuntu.com/ubuntu-ports %s-updates main universe multiverse restricted\n" "$release" >> /etc/apt/sources.list.d/arm-ports.list \
 && printf "deb [arch=arm64,armhf] http://ports.ubuntu.com/ubuntu-ports %s-backports main universe multiverse restricted\n" "$release" >> /etc/apt/sources.list.d/arm-ports.list \
 && printf "deb [arch=arm64,armhf] http://ports.ubuntu.com/ubuntu-ports %s-security main universe multiverse restricted\n" "$release" >> /etc/apt/sources.list.d/arm-ports.list

 # Host
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        crossbuild-essential-arm64 \
        crossbuild-essential-armhf \
        ninja-build \
        ca-certificates \
        clang \
        libclang-dev \
        llvm-dev \
        gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
        libopencv-dev \
        x11-apps \
        libtinfo6 libncurses6 \
        protobuf-compiler \
 && apt-get install -y \
        libopencv-dev:arm64 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# VS-Code Dev Container
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

USER $USERNAME
WORKDIR /home/$USERNAME

# pyenvのインストール
RUN curl https://pyenv.run | bash
ENV PYENV_ROOT="/home/$USERNAME/.pyenv"
ENV PATH="$PYENV_ROOT/bin:$PATH"

# pyenvの初期化設定
RUN echo 'eval "$(pyenv init -)"' >> ~/.bashrc \
 && echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc

# Python バージョンをインストール
ENV PYTHON_VERSION=3.12.7
RUN $PYENV_ROOT/bin/pyenv install $PYTHON_VERSION \
    && $PYENV_ROOT/bin/pyenv global $PYTHON_VERSION \
    && $PYENV_ROOT/bin/pyenv rehash
RUN $PYENV_ROOT/shims/pip install --upgrade pip setuptools wheel
RUN $PYENV_ROOT/shims/pip install numpy matplotlib jupyterlab pandas scipy scikit-learn scikit-image notebook

# Rust install
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN echo 'export PATH=$HOME/.cargo/bin:$PATH' >> /home/$USERNAME/.bashrc
ENV PATH="/home/${USERNAME}/.cargo/bin:${PATH}"
RUN rustup target add aarch64-unknown-linux-gnu
RUN rustup target add arm-unknown-linux-gnueabihf
RUN cargo install cross
RUN cargo install evcxr_jupyter
RUN cargo install verylup \
 && verylup setup
RUN cargo install --git https://github.com/ryuz/jelly-fpga-loader.git --tag v0.1.0

# Finish
USER root

#RUN groupadd -g 999 dockersock \
# && usermod -aG dockersock vscode

ENV DEBIAN_FRONTEND=dialog
