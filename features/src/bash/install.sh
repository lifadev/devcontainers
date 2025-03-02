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
  xz-utils
rm -rf /var/lib/apt/lists/*

#---

#? https://github.com/koalaman/shellcheck/tags
#? manual checksum
PACKAGE_VERSION=0.10.0
case $ARCH in
amd64)
  PACKAGE_URL="https://github.com/koalaman/shellcheck/releases/download/v${PACKAGE_VERSION}/shellcheck-v${PACKAGE_VERSION}.linux.x86_64.tar.xz"
  PACKAGE_SUM=6c881ab0698e4e6ea235245f22832860544f17ba386442fe7e9d629f8cbedf87
  ;;
arm64)
  PACKAGE_URL="https://github.com/koalaman/shellcheck/releases/download/v${PACKAGE_VERSION}/shellcheck-v${PACKAGE_VERSION}.linux.aarch64.tar.xz"
  PACKAGE_SUM=324a7e89de8fa2aed0d0c28f3dab59cf84c6d74264022c00c22af665ed1a09bb
  ;;
esac

PACKAGE=/tmp/package.tar.xz
curl -fLsS "$PACKAGE_URL" -o $PACKAGE
echo "$PACKAGE_SUM $PACKAGE" | sha256sum -c

INSTALL_DIR=/opt/bin
mkdir -p $INSTALL_DIR
tar -xJf $PACKAGE --strip-components 1 -C $INSTALL_DIR --wildcards "*/shellcheck"
rm -f $PACKAGE

#---

#? https://github.com/mvdan/sh/tags
#? sha256sums.txt
PACKAGE_VERSION=3.10.0
case $ARCH in
amd64)
  PACKAGE_URL="https://github.com/mvdan/sh/releases/download/v${PACKAGE_VERSION}/shfmt_v${PACKAGE_VERSION}_linux_amd64"
  PACKAGE_SUM=1f57a384d59542f8fac5f503da1f3ea44242f46dff969569e80b524d64b71dbc
  ;;
arm64)
  PACKAGE_URL="https://github.com/mvdan/sh/releases/download/v${PACKAGE_VERSION}/shfmt_v${PACKAGE_VERSION}_linux_arm64"
  PACKAGE_SUM=9d23013d56640e228732fd2a04a9ede0ab46bc2d764bf22a4a35fb1b14d707a8
  ;;
esac

PACKAGE=/tmp/package
curl -fLsS "$PACKAGE_URL" -o "$PACKAGE"
echo "$PACKAGE_SUM $PACKAGE" | sha256sum -c

INSTALL_DIR=/opt/bin
mkdir -p $INSTALL_DIR
mv $PACKAGE $INSTALL_DIR/shfmt
chmod +x $INSTALL_DIR/shfmt

#---

mkdir -p /etc/bashrc.d

cat <<EOF >>/etc/bash.bashrc
if [ -d /etc/bashrc.d ]; then
  for i in /etc/bashrc.d/*; do
    if [ -r "\$i" ]; then
      # shellcheck disable=SC1090
      . "\$i"
    fi
  done
  unset i
fi
EOF
