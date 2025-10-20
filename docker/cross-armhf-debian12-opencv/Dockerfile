FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture armhf \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
        build-essential \
        crossbuild-essential-armhf \
        pkg-config \
        cmake \
        ninja-build \
        libssl-dev \
        clang \
        libclang-dev \
        llvm-dev \
        protobuf-compiler \
 && apt-get install -y \
        libopencv-dev:armhf \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
