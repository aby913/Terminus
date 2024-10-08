#!/usr/bin/env bash

BASE_DIR=$(dirname $(realpath -s $0))
echo "Push Deps to S3 base_dir: ${BASE_DIR}"

if [ ! -d ".dependencies" ]; then
    exit 1
fi

PLATFORM=${1:-linux/amd64}

path=""
if [ x"$PLATFORM" == x"linux/arm64" ]; then
    path="arm64/"
fi

apt update && apt install -y tree

pushd ${BASE_DIR}/../.dependencies
fileprefix="deps"
name=$(md5sum dependencies.mf |awk '{print $1}')
echo "filename: ${fileprefix}-${name}.tar.gz"
# curl -fsSLI https://dc3p1870nn3cj.cloudfront.net/${path}${fileprefix}-$name.tar.gz > /dev/null
aws s3 ls s3://zhangliang-s3-test/test/${path}${fileprefix}-$name.tar.gz
if [ $? -eq 0 ]; then
    echo "dependencies file ${fileprefix}-${name}.tar.gz exists, STOP..."
    # exit 1
fi

bash ${BASE_DIR}/download-deps.sh $PLATFORM

name=$(md5sum dependencies.mf |awk '{print $1}')
echo "filename: ${fileprefix}-${name}.tar.gz"
# curl -fsSLI https://dc3p1870nn3cj.cloudfront.net/${path}${fileprefix}-$name.tar.gz > /dev/null
aws s3 ls s3://zhangliang-s3-test/test/${path}${fileprefix}-$name.tar.gz
if [ $? -ne 0 ]; then
    echo "dependencies file ${fileprefix}-${name}.tar.gz not found, prepare to upload to S3"
    tar -czf ./$name.tar.gz ./components ./pkg ./dependencies.mf && cp ./$name.tar.gz ../
    popd
    rm -rf ./.dependencies/
    # --acl=public-read
    aws s3 cp $name.tar.gz s3://zhangliang-s3-test/test/${path}${fileprefix}-$name.tar.gz
    echo "upload $name completed"
else
    echo "dependencies file ${fileprefix}-${name}.tar.gz exists, EXIT..."
fi