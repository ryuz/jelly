FROM ryuz88/zynqmp_opencv

LABEL maintainter="ryuz88"

# gRPC
RUN apt-get install -y build-essential autoconf libtool pkg-config
RUN git clone --recurse-submodules -b v1.34.1 --depth 1 --shallow-submodules https://github.com/grpc/grpc; \
    cd grpc;mkdir -p cmake/build; cd cmake/build;cmake -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF ../.. ; \
    make;make install;cd ../../..;rm -fr grpc

# entrypoint
COPY ./files/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
