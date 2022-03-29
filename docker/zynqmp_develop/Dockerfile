FROM ubuntu:20.04

LABEL maintainter="ryuz88"

# update
RUN apt-get update

# sshd
RUN apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
RUN sed -i 's/#Port 22/Port 20022/' /etc/ssh/sshd_config
RUN sed -i 's/#X11DisplayOffset 10/X11DisplayOffset 10/' /etc/ssh/sshd_config
RUN sed -i 's/#X11UseLocalhost yes/X11UseLocalhost no/' /etc/ssh/sshd_config
EXPOSE 20022

# sudo
RUN apt-get install -y sudo
RUN echo 'root:admin' | chpasswd

# install
RUN apt-get install -y git
RUN apt-get install -y build-essential
RUN apt-get install -y device-tree-compiler
RUN apt-get install -y xauth

# bootgen
RUN apt-get install -y libssl-dev
RUN git clone https://github.com/Xilinx/bootgen;cd bootgen;make;cp bootgen /usr/local/bin;cd ..;rm -fr bootgen

# entrypoint
COPY ./files/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
