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

#? https://github.com/aws/aws-cli/tags
#? sha256sum
PACKAGE_VERSION=2.24.19
case $ARCH in
amd64)
  PACKAGE_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64-$PACKAGE_VERSION.zip"
  PACKAGE_SUM=ad2114f0b903eaaf2daecadae514c254d0299f3365cff4d369dee6c4ac00fcc5
  ;;
arm64)
  PACKAGE_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64-$PACKAGE_VERSION.zip"
  PACKAGE_SUM=6a5c6175bcc1d5fdfef4cc93eec984bc1254c0a3f081db3cc10435cf476af0d5
  ;;
esac

PACKAGE=/tmp/package.zip
curl -fLsS "$PACKAGE_URL" -o $PACKAGE
echo "$PACKAGE_SUM $PACKAGE" | sha256sum -c

BUILD_DIR=/tmp/package
unzip -q $PACKAGE -d $BUILD_DIR
rm -f $PACKAGE

INSTALL_DIR=/opt/aws2
$BUILD_DIR/aws/install -i $INSTALL_DIR -b /opt/bin
rm -rf $BUILD_DIR

#---

mkdir -p /etc/bash_completion.d

cat <<EOF >>/etc/bash_completion.d/aws2
complete -C '/opt/bin/aws_completer' aws
EOF
