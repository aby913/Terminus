#!/usr/bin/env bash



BASE_DIR=$(dirname $(realpath -s $0))
rm -rf ${BASE_DIR}/../.dist
rm -rf ${BASE_DIR}/../.manifest
rm -rf ${BASE_DIR}/../.dependencies
DIST_PATH="${BASE_DIR}/../.dist/install-wizard" 
VERSION=$1
PLATFORM=${2:-linux/amd64}

set -o pipefail
set -e

DIST_PATH=${DIST_PATH} bash ${BASE_DIR}/package.sh
cp ${BASE_DIR}/upgrade.sh ${DIST_PATH}/.

# bash ${BASE_DIR}/image-manifest.sh
bash ${BASE_DIR}/deps-manifest.sh $PLATFORM

# pushd ${BASE_DIR}/../.manifest
# bash $BASE_DIR/save-images.sh images.mf $PLATFORM
# popd

pushd ${BASE_DIR}/../.dependencies
bash $BASE_DIR/save-deps.sh $PLATFORM
popd

pushd $DIST_PATH

# rm -rf images
rm -rf components
rm -rf pkg

# mv ${BASE_DIR}/../.manifest images


if [ -d ${BASE_DIR}/../.dependencies/components ]; then
    mv ${BASE_DIR}/../.dependencies/components components
    echo "---1---"
    mv ./components/terminus-cli*.tar.gz ./
    echo "---2---"
fi
if [ -d ${BASE_DIR}/../.dependencies/pkg ]; then
    mv ${BASE_DIR}/../.dependencies/pkg pkg
fi
if [ -f ${BASE_DIR}/../.dependencies/dependencies.mf ]; then
    cp ${BASE_DIR}/../.dependencies/dependencies.mf ./
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    TAR=gtar
    SED="sed -i '' -e"
else
    TAR=tar
    SED="sed -i"
fi

if [ ! -z $VERSION ]; then
    sh -c "$SED 's/#__VERSION__/${VERSION}/' wizard/config/settings/templates/terminus_cr.yaml"
    sh -c "$SED 's/#{{LATEST_VERSION}}/${VERSION}/' publicInstaller.latest"
    VERSION="v${VERSION}"
else
    VERSION="debug"
fi

$TAR --exclude=wizard/tools --exclude=.git -zcvf ${BASE_DIR}/../install-wizard-${VERSION}.tar.gz .

popd