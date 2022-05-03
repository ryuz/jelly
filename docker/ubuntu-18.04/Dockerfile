FROM ubuntu:18.04

LABEL maintainter="ryuz88"

# install
ENV DEBIAN_FRONTEND=noninteractive
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
        tofrodos \
        iproute2 \
        gawk \
        net-tools \
        libncurses5-dev \
        libncursesw5-dev \
        zlib1g:i386 \
        libssl-dev \
        flex \
        bison \
        libselinux1 \
        gnupg \
        wget \
        diffstat \
        chrpath \
        socat \
        xterm \
        autoconf \
        libtool \
        tar \
        unzip \
        texinfo \
        zlib1g-dev \
        gcc-multilib \
        build-essential \
        screen \
        pax \
        gzip \
        python2.7 \
        binutils \
        cpio \
        expect \
        file \
        fonts-noto-cjk \
        git \
        gosu \
        lib32z1-dev \
        libglib2.0-dev \
        libgtk2.0-0 \
        libsdl1.2-dev \
        libtool-bin \
        locales \
        lsb-release \
        ncurses-dev \
        sudo \
        u-boot-tools \
        vim \
        xvfb \
        bc \
        rsync && \
    apt-get clean && \
    apt-get autoclean && \
    ln -fs /bin/bash /bin/sh && \
    \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /var/cache/* && \
    rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8 && \
    update-locale
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8


# sshd
RUN apt-get update
RUN apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
RUN sed -i 's/#Port 22/Port 18022/' /etc/ssh/sshd_config
RUN sed -i 's/#X11DisplayOffset 10/X11DisplayOffset 10/' /etc/ssh/sshd_config
RUN sed -i 's/#X11UseLocalhost yes/X11UseLocalhost no/' /etc/ssh/sshd_config
RUN sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
EXPOSE 18022

# sudo
RUN apt-get install -y sudo
RUN echo 'root:admin' | chpasswd

# entrypoint
COPY ./files/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
