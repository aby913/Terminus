#!/usr/bin/env bash

VERSION=$1
BASE_DIR=$(dirname $(realpath -s $0))
DIST_PATH="${BASE_DIR}/../.dist/install-wizard" 
USER=ubuntu

cat > ./Dockerfile.v${VERSION} << _END
FROM ubuntu:22.04

# ARG USER

# RUN apt-get update -y && apt-get -y install iproute2 curl sudo software-properties-common pciutils openssh-client iputils-ping vim

RUN /bin/bash -c 'addgroup ${USER}; useradd -m -s /bin/bash -g ${USER} ${USER}; echo "${USER}:1" | chpasswd'

COPY ./wsl.conf /etc/wsl.conf
COPY ${DIST_PATH}/install.sh /home/${USER}/
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
hostname=${USER}

[user]
_END

name="install-wizard-wsl-image-v${VERSION}"
checksum="$name.checksum.txt"

echo "---1--- [${DIST_PATH}] [${BASE_DIR}]"
pwd
echo "---2---"
ls
echo "---3---"
ls ${BASE_DIR}/
echo "---4---"
ls ${DIST_PATH}/
echo "---5---"

cat ./Dockerfile.v${VERSION}
echo "---6---"
cat ./wsl.conf
echo "---7---"


# curl -fsSLI https://dc3p1870nn3cj.cloudfront.net/$name.tar.gz > /dev/null
aws s3 ls s3://zhangliang-s3-test/test2/$name.tar.gz > /dev/null
if [ $? -ne 0 ]; then
    echo "build wsl image"
    set -e
    # --build-arg USER=ubuntu 
    docker build -f ./Dockerfile.v${VERSION} -t install-wizard:v${VERSION} .
    cid=$(docker run -it --name terminus-v${VERSION} -d install-wizard:v${VERSION})
    # echo "---4--- ${cid}"
    docker export -o ./${name}.tar.gz ${cid}
    md5sum ./${name}.tar.gz > ./${checksum}

    aws s3 cp ./${name}.tar.gz s3://zhangliang-s3-test/test2/${name}.tar.gz
    aws s3 cp ./${checksum} s3://zhangliang-s3-test/test2/${checksum}
    echo "upload $name completed"
    set +e
fi


echo "---8---"
ls
echo "---9---"