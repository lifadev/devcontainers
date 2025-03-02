#!/bin/bash

set -eux

NPM_VERSION=${NPM_VERSION:-undefined}

#---

if [ "$UID" -ne 0 ]; then
  echo -e "(!) User must be root: $UID"
  exit 1
fi

ARCH="$(dpkg --print-architecture)"
if [ "$ARCH" != 'amd64' ] && [ "$ARCH" != 'arm64' ]; then
  echo "(!) Unsupported architecture: $ARCH"
  exit 1
fi

#---

apt update --quiet
apt install --yes --no-install-recommends \
  ca-certificates \
  curl \
  xz-utils
rm -rf /var/lib/apt/lists/*

#---

#? https://github.com/nodejs/node/tags
#? SHASUMS256.txt
PACKAGE_VERSION=23.9.0
case $ARCH in
amd64)
  PACKAGE_URL="https://nodejs.org/dist/v${PACKAGE_VERSION}/node-v${PACKAGE_VERSION}-linux-x64.tar.xz"
  PACKAGE_SUM=0b4ece2aa678e6891b9abf6118d5393867ab07b3e31c8d8c4c34e97840fa8749
  ;;
arm64)
  PACKAGE_URL="https://nodejs.org/dist/v${PACKAGE_VERSION}/node-v${PACKAGE_VERSION}-linux-arm64.tar.xz"
  PACKAGE_SUM=dc0d93c5e4ae41c8fe75b64399c4d1fe3c15e2bfa3f55f92f8697bb16397585b
  ;;
esac

PACKAGE=/tmp/package.tar.xz
curl -fLsS "$PACKAGE_URL" -o $PACKAGE
echo "$PACKAGE_SUM $PACKAGE" | sha256sum -c

INSTALL_DIR=/opt/node23
mkdir -p $INSTALL_DIR
tar -xJf $PACKAGE --strip-components 1 -C $INSTALL_DIR
rm -f $PACKAGE

#---

#? https://github.com/npm/cli/tags
npm install -g npm@11.1.0

#---

mkdir -p /etc/bash_completion.d

cat <<EOF >>/etc/bash_completion.d/node23-npm
eval "\$(npm completion)"
EOF
