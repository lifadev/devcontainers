#!/bin/bash

set -eux

# region Options

NPM_VERSION=${NPM_VERSION:-undefined}

# endregion

# region Prerequisites

if [ "$UID" -ne 0 ]; then
  echo -e "(!) User must be root: $UID"
  exit 1
fi

ARCH="$(dpkg --print-architecture)"
if [ "$ARCH" != 'amd64' ] && [ "$ARCH" != 'arm64' ]; then
  echo "(!) Unsupported architecture: $ARCH"
  exit 1
fi

# endregion

# region Installations

# region `node`

#? https://github.com/nodejs/node/tags
#? SHASUMS256.txt
PACKAGE_VERSION=23.6.1
case $ARCH in
amd64)
  PACKAGE_URL="https://nodejs.org/dist/v${PACKAGE_VERSION}/node-v${PACKAGE_VERSION}-linux-x64.tar.xz"
  PACKAGE_SUM=9387c4bf8f175e81cb2f004f3f4b2cd96abfb708df3755142e878effe035fcc5
  ;;
arm64)
  PACKAGE_URL="https://nodejs.org/dist/v${PACKAGE_VERSION}/node-v${PACKAGE_VERSION}-linux-arm64.tar.xz"
  PACKAGE_SUM=e9a709ea4142c0c269d7e670e37e65cf549bf69d62342907cd15a49ba7da1748
  ;;
esac

PACKAGE=/tmp/package.tar.xz
curl -fLsS "$PACKAGE_URL" -o $PACKAGE
echo "$PACKAGE_SUM $PACKAGE" | sha256sum -c
mkdir -p "$NODE_INSTALL_DIR"
tar -xJf $PACKAGE --strip-components 1 -C "$NODE_INSTALL_DIR"
rm -f $PACKAGE

export PATH=$NODE_BIN_DIR:$PATH

# endregion

# region `npm`

npm install -g "npm@$NPM_VERSION"

# endregion

# endregion
