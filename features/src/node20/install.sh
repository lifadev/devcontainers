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

INSTALL_DIR=/opt
BIN_DIR=$INSTALL_DIR/bin
mkdir -p $BIN_DIR

# endregion

# region Installations

# region Node

apt update --quiet
apt install --yes --no-install-recommends \
  ca-certificates \
  curl \
  xz-utils
rm -rf /var/lib/apt/lists/*

#? https://github.com/nodejs/node/tags
#? SHASUMS256.txt
PACKAGE_VERSION=20.18.3

case $ARCH in
amd64)
  PACKAGE_URL="https://nodejs.org/dist/v${PACKAGE_VERSION}/node-v${PACKAGE_VERSION}-linux-x64.tar.xz"
  PACKAGE_SUM=595bcc9a28e6d1ee5fc7277b5c3cb029275b98ec0524e162a0c566c992a7ee5c
  ;;
arm64)
  PACKAGE_URL="https://nodejs.org/dist/v${PACKAGE_VERSION}/node-v${PACKAGE_VERSION}-linux-arm64.tar.xz"
  PACKAGE_SUM=c03412ab9c0ed30468e4d03e56d2e35c5ae761a98deb16727c7af2fe5be34700
  ;;
esac

PACKAGE=/tmp/package.tar.xz
curl -fLsS "$PACKAGE_URL" -o $PACKAGE
echo "$PACKAGE_SUM $PACKAGE" | sha256sum -c
mkdir -p "$NODE20_INSTALL_DIR"
tar -xJf $PACKAGE --strip-components 1 -C "$NODE20_INSTALL_DIR"
rm -f $PACKAGE

export PATH=$NODE20_BIN_DIR:$PATH

# endregion

# region Package managers

#? https://github.com/npm/cli/tags
npm install -g "npm@$NPM_VERSION"

# endregion

# endregion

# region Shell integration

mkdir -p /etc/bash_completion.d

cat <<EOF >>/etc/bash_completion.d/node20-npm
eval "\$(npm completion)"
EOF

# endregion
