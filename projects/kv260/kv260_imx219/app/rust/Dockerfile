FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN release=$(. /etc/os-release && echo "$UBUNTU_CODENAME") \
 && mv /etc/apt/sources.list /etc/apt/sources.list.amd64 \
 && printf "deb [arch=amd64] http://archive.ubuntu.com/ubuntu %s main universe multiverse restricted\n" "$release" > /etc/apt/sources.list \
 && printf "deb [arch=amd64] http://archive.ubuntu.com/ubuntu %s-updates main universe multiverse restricted\n" "$release" >> /etc/apt/sources.list \
 && printf "deb [arch=amd64] http://archive.ubuntu.com/ubuntu %s-backports main universe multiverse restricted\n" "$release" >> /etc/apt/sources.list \
 && printf "deb [arch=amd64] http://security.ubuntu.com/ubuntu %s-security main universe multiverse restricted\n" "$release" >> /etc/apt/sources.list \
 && rm -f /etc/apt/sources.list.d/* \
 && printf "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports %s main universe multiverse restricted\n" "$release" > /etc/apt/sources.list.d/arm64-ports.list \
 && printf "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports %s-updates main universe multiverse restricted\n" "$release" >> /etc/apt/sources.list.d/arm64-ports.list \
 && printf "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports %s-backports main universe multiverse restricted\n" "$release" >> /etc/apt/sources.list.d/arm64-ports.list \
 && printf "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports %s-security main universe multiverse restricted\n" "$release" >> /etc/apt/sources.list.d/arm64-ports.list \
 && dpkg --add-architecture arm64 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
        build-essential \
        crossbuild-essential-arm64 \
        pkg-config \
        cmake \
        ninja-build \
        libssl-dev \
        clang \
        libclang-dev \
        llvm-dev \
 && apt-get install -y \
        libopencv-dev:arm64 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
