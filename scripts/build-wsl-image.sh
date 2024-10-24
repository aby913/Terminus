#!/usr/bin/env bash

VERSION=$1
BASE_DIR=$(dirname $(realpath -s $0))
DIST_PATH="${BASE_DIR}/../.dist/install-wizard" 
USER=ubuntu

cp ${DIST_PATH}/install.sh ./
CLI_VERSION=$(cat ./install.sh |grep 'CLI_VERSION=' | awk -F'=' '{print $2}' | tr -d '"')
CLI_FILE="terminus-cli-v${CLI_VERSION}_linux_amd64.tar.gz"
CLI_URL="https://dc3p1870nn3cj.cloudfront.net/${CLI_FILE}"
curl -Lo ./${CLI_FILE} ${CLI_URL} && tar xvf ./${CLI_FILE}

cat > ./Dockerfile.v${VERSION} << _END
FROM ubuntu:22.04

RUN apt-get update -y && apt-get -y install iproute2 curl sudo software-properties-common pciutils openssh-client iputils-ping vim

RUN /bin/bash -c 'addgroup ${USER}; useradd -m -s /bin/bash -g ${USER} ${USER}; echo "${USER}:${USER}" | chpasswd'
RUN mkdir -p /home/${USER}/.terminus && chown ${USER}:${USER} /home/${USER}/.terminus && mkdir -p /home/${USER}/.terminus/versions/v${VERSION}

COPY ./wsl.conf /etc/wsl.conf
COPY --chown=${USER}:${USER} ./install.sh /home/${USER}/
COPY ./install-wizard-v${VERSION}.tar.gz /home/${USER}/.terminus/versions/v${VERSION}/
COPY ./${CLI_FILE} /home/${USER}/
COPY ./terminus-cli /home/${USER}/

RUN cd /home/${USER}/.terminus/versions/v${VERSION}/ && tar zxvf install-wizard-v${VERSION}.tar.gz && chown -R root:root /home/${USER}/.terminus/versions/ && chmod -R 0655 /home/${USER}/.terminus/versions/

RUN /bin/sh -c 'echo "default=${USER}" >> /etc/wsl.conf; \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers;'

RUN sudo /home/${USER}/terminus-cli terminus download component --base-dir /home/${USER}/.terminus --manifest /home/${USER}/.terminus/versions/v${VERSION}/installation.manifest --kube k3s --version ${VERSION}

RUN sudo rm -rf /home/${USER}/terminus-cli* && sudo rm -rf /home/${USER}/.terminus/logs

USER ${USER}
WORKDIR /home/${USER}

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

# curl -fsSLI https://dc3p1870nn3cj.cloudfront.net/$name.tar.gz > /dev/null
aws s3 ls s3://zhangliang-s3-test/test2/$name.tar.gz > /dev/null
if [ $? -ne 0 ]; then
    echo "build wsl image"
    set -e
    docker build -f Dockerfile.v${VERSION} -t install-wizard:v${VERSION} .
    cid=$(docker run -it --name terminus-v${VERSION} -d install-wizard:v${VERSION})
    docker exec ${cid} bash -c "rm -rf /home/${USER}/terminus-cli"
    docker export -o ${name}.tar ${cid}

    sudo apt-get clean
    sudo apt-get autoremove -y
    sudo rm -rf /usr/share/dotnet
    sudo rm -rf /usr/local/lib/android
    sudo rm -rf /opt/ghc
    sudo rm -rf /tmp/*

    gzip -9 ${name}.tar
    md5sum ${name}.tar.gz > ${checksum}

    aws s3 cp ${name}.tar.gz s3://zhangliang-s3-test/test2/${name}.tar.gz
    aws s3 cp ${checksum} s3://zhangliang-s3-test/test2/${checksum}
    echo "upload $name completed"
    set +e
fi