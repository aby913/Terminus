#!/usr/bin/env bash

VERSION=$1

cat > ./Dockerfile.${VERSION} << _END
FROM ubuntu:22.04

ARG USER

RUN apt-get update -y && apt-get -y install iproute2 curl sudo software-properties-common pciutils openssh-client openssh-server iputils-ping vim

RUN /bin/bash -c 'addgroup ${USER}; useradd -m -s /bin/bash -g ${USER} ${USER}; echo "${USER}:1" | chpasswd'

COPY ./wsl.conf /etc/wsl.conf
COPY ./install-wizard-v${VERSION}.tar.gz /home/${USER}/
RUN /bin/sh -c 'echo "default=${USER}" >> /etc/wsl.conf; \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers;'
_END

cat > ./wsl.conf << _END
[boot]
systemd=true
command="mount --make-rshared /"
[network]
generateHosts=false
generateResolvConf=false
hostname=terminus

[user]
_END

echo "build wsl image"

docker build -f ./Dockerfile.${VERSION} --build-arg USER=ubuntu -t install-wizard-v${VERSION}:${VERSION} .
cid=$(docker run -it -d install-wizard-v${VERSION}:${VERSION})
docker export -o ./install-wizard-v${VERSION}.tar.gz ${cid}

echo '---1---'
pwd
echo '---2---'
ls
echo '---3---'
cat ./build/installer/install.sh
echo '---4---'
docker images
echo '---5---'

