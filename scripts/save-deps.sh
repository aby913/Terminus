BASE_DIR=$(dirname $(realpath -s $0))
PLATFORM=${1:-linux/amd64}

path=""
if [ x"$PLATFORM" == x"linux/arm64" ]; then
    path="arm64/"
fi

fileprefix="deps"
name=$(md5sum dependencies.mf |awk '{print $1}')
echo "READY to find this deps ${fileprefix}-${name}.tar.gz"

# curl -fsSLI https://dc3p1870nn3cj.cloudfront.net/${path}${fileprefix}-${name}.tar.gz > /dev/null
aws s3 ls s3://zhangliang-s3-test/test/${path}${fileprefix}-$name.tar.gz
if [ $? -eq 0 ]; then
    echo "---a1---"
    # curl -fsSL https://dc3p1870nn3cj.cloudfront.net/${path}${fileprefix}-${name}.tar.gz -o ${fileprefix}-${name}.tar.gz

    # tar -zxvf ${fileprefix}-${name}.tar.gz
    # rm -rf ${fileprefix}-${name}.tar.gz
else
    echo "---a2---"
    bash ${BASE_DIR}/download-deps.sh $PLATFORM
fi