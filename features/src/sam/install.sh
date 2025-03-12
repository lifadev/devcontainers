#!/bin/bash

set -eux

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
  unzip
rm -rf /var/lib/apt/lists/*

#---

#? https://github.com/aws/aws-sam-cli/tags
#? plain text
PACKAGE_VERSION=1.135.0
case $ARCH in
amd64)
  PACKAGE_URL="https://github.com/aws/aws-sam-cli/releases/download/v${PACKAGE_VERSION}/aws-sam-cli-linux-x86_64.zip"
  PACKAGE_SUM="873ef14b43c03be925a1fab8b11df0c333980c03c45f0be96c694513d61a134e"
  ;;
arm64)
  PACKAGE_URL="https://github.com/aws/aws-sam-cli/releases/download/v${PACKAGE_VERSION}/aws-sam-cli-linux-arm64.zip"
  PACKAGE_SUM="499ae2420fad063b24706fdc1f10085de22ea5d6c4f89aaf67d3ebe470385587"
  ;;
esac

PACKAGE=/tmp/package.zip
curl -fLsS "$PACKAGE_URL" -o $PACKAGE
echo "$PACKAGE_SUM $PACKAGE" | sha256sum -c

BUILD_DIR=/tmp/package
unzip $PACKAGE -d $BUILD_DIR
rm -rf $PACKAGE

INSTALL_DIR=/opt/sam
$BUILD_DIR/install -i $INSTALL_DIR -b /opt/bin
rm -rf $BUILD_DIR

#---

#? https://github.com/aws/aws-sam-cli/issues/6842
