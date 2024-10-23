#!/usr/bin/env bash

VERSION=$1
BASE_DIR=$(dirname $(realpath -s $0))
DIST_PATH="${BASE_DIR}/../.dist/install-wizard" 

cat > ./Dockerfile.v${VERSION} << _END
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

echo "---0--- ${BASE_DIR} ${DIST_PATH}"
echo "build wsl image"

echo '---1---'
docker build -f ./Dockerfile.v${VERSION} --build-arg USER=ubuntu -t install-wizard:v${VERSION} .
echo '---2---'
docker images
echo '---3---'
cid=$(docker run -it -d install-wizard:v${VERSION})
echo "---4--- ${cid}"
docker ps
echo '---5---'
docker export -o ./install-wizard-wsl-image-v${VERSION}.tar.gz ${cid}
echo '---6---'

pwd
echo '---7---'
ls
echo '---8---'
cat ${DIST_PATH}/install.sh
echo '---9---'

