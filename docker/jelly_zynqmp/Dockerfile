FROM ubuntu:20.04

LABEL maintainter="ryuz88"

# update
RUN apt-get update
RUN apt-get -y upgrade

# basic
RUN apt-get install -y build-essential && \
    apt-get install -y git

# opencv
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y cmake libeigen3-dev && \
    apt-get install -y libgtk-3-dev qt5-default freeglut3-dev libvtk6-qt-dev && \
    apt-get install -y libtbb-dev && \
    apt-get install -y libjpeg-dev libpng++-dev libtiff-dev libopenexr-dev libwebp-dev && \
    apt-get install -y libhdf5-dev && \
    apt-get install -y wget unzip

RUN mkdir /opencv
COPY ./files/build_opencv3.sh /opencv
RUN cd opencv;bash build_opencv3.sh;cd ..;rm -fr opencv

# bootgen
RUN apt-get install -y device-tree-compiler && \
    apt-get install -y libssl-dev
RUN git clone https://github.com/Xilinx/bootgen;cd bootgen;make;cp bootgen /usr/local/bin;cd ..;rm -fr bootgen

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

# entrypoint
COPY ./files/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
