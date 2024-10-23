#!/usr/bin/env bash

VERSION=$1
BASE_DIR=$(dirname $(realpath -s $0))
DIST_PATH="${BASE_DIR}/../.dist/install-wizard" 
USER=ubuntu

cat > ./Dockerfile.v${VERSION} << _END
FROM ubuntu:22.04

# RUN apt-get update -y && apt-get -y install iproute2 curl sudo software-properties-common pciutils openssh-client iputils-ping vim

RUN /bin/bash -c 'addgroup ${USER}; useradd -m -s /bin/bash -g ${USER} ${USER}; echo "${USER}:ubuntu" | chpasswd'

COPY ./wsl.conf /etc/wsl.conf
COPY ./install.sh /home/${USER}/
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
hostname=ubuntu

[user]
_END

name="install-wizard-wsl-image-v${VERSION}"
checksum="$name.checksum.txt"
cp ${DIST_PATH}/install.sh ./

# curl -fsSLI https://dc3p1870nn3cj.cloudfront.net/$name.tar.gz > /dev/null
aws s3 ls s3://zhangliang-s3-test/test2/$name.tar.gz > /dev/null
if [ $? -ne 0 ]; then
    echo "build wsl image"
    set -e
    # --build-arg USER=ubuntu 
    docker build -f ./Dockerfile.v${VERSION} -t install-wizard:v${VERSION} .
    cid=$(docker run -it --name terminus-v${VERSION} -d install-wizard:v${VERSION})
    docker export -o ./${name}.tar.gz ${cid}
    md5sum ./${name}.tar.gz > ./${checksum}

    aws s3 cp ./${name}.tar.gz s3://zhangliang-s3-test/test2/${name}.tar.gz
    aws s3 cp ./${checksum} s3://zhangliang-s3-test/test2/${checksum}
    echo "upload $name completed"
    set +e
fi