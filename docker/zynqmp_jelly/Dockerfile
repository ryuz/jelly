FROM ryuz88/zynqmp_cv_grpc:latest

LABEL maintainter="ryuz88"

# for RPU
RUN apt-get install -y gcc-arm-none-eabi
RUN apt-get install -y libnewlib-arm-none-eabi

# risc-v
RUN apt-get install -y autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev
RUN git clone https://github.com/riscv/riscv-gnu-toolchain
RUN cd riscv-gnu-toolchain; ./configure --prefix=/opt/riscv --enable-multilib; make
RUN cd /;rm -fr riscv-gnu-toolchain

# python 
RUN apt install -y python3-pip
RUN pip install numpy

# entrypoint
COPY ./files/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
