#!/usr/bin/env bash

DOCKERFILE=`FROM ubuntu:22.04

ARG USER

RUN apt-get update -y && apt-get -y install iproute2 curl sudo software-properties-common pciutils openssh-client openssh-server iputils-ping vim

RUN /bin/bash -c 'addgroup ${USER}; useradd -m -s /bin/bash -g ${USER} ${USER}; echo "${USER}:1" | chpasswd'

COPY ./wsl.conf /etc/wsl.conf
RUN /bin/sh -c 'echo "default=${USER}" >> /etc/wsl.conf; \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers;'
`
WSLCONFIG=`[boot]
systemd=true
command="mount --make-rshared /"
[network]
generateHosts=false
generateResolvConf=false
hostname=terminus

[user]
`

VERSION=$1

echo "build wsl image"

echo "${DOCKERFILE}" > ./Dockerfile.${VERSION}
echo "${WSLCONFIG}" > ./wsl.conf

docker build -f ./Dockerfile.wsl --build-arg USER=ubuntu -t install-wizard-v${VERSION}:${VERSION} .
cid=$(docker run -it -d install-wizard-v${VERSION}:${VERSION})
docker export -o ./install-wizard-v${VERSION}.tar.gz ${cid}

echo '---1---'
pwd
echo '---2---'
ls
echo '---3---'
docker ps
echo '---4---'
