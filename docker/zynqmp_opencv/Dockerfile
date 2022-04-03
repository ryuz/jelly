FROM ryuz88/zynqmp_develop:latest

LABEL maintainter="ryuz88"

# opencv
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y cmake libeigen3-dev
RUN apt-get install -y libgtk-3-dev qt5-default freeglut3-dev libvtk6-qt-dev
RUN apt-get install -y libtbb-dev
RUN apt-get install -y libjpeg-dev libpng++-dev libtiff-dev libopenexr-dev libwebp-dev
RUN apt-get install -y libhdf5-dev
RUN apt-get install -y wget unzip

RUN mkdir /opencv
COPY ./files/build_opencv3.sh /opencv
RUN cd opencv;bash build_opencv3.sh;cd ..;rm -fr opencv

# entrypoint
COPY ./files/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
