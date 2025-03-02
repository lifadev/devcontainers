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
  curl
rm -rf /var/lib/apt/lists/*

#---

#? https://github.com/astral-sh/ruff/tags
#? .sha256
PACKAGE_VERSION=0.9.9
case $ARCH in
amd64)
  PACKAGE_URL="https://github.com/astral-sh/ruff/releases/download/${PACKAGE_VERSION}/ruff-x86_64-unknown-linux-gnu.tar.gz"
  PACKAGE_SUM=49592925719ee59a7e6675a95dc20e76c0b921b498500a54b1cce3c314fdf794
  ;;
arm64)
  PACKAGE_URL="https://github.com/astral-sh/ruff/releases/download/${PACKAGE_VERSION}/ruff-aarch64-unknown-linux-gnu.tar.gz"
  PACKAGE_SUM=34b4ea311560d5e7f80597eaf3dede9ded194dffe131d7fee8841904792a644c
  ;;
esac

PACKAGE=/tmp/package.tar.gz
curl -fLsS "$PACKAGE_URL" -o $PACKAGE
echo "$PACKAGE_SUM $PACKAGE" | sha256sum -c

INSTALL_DIR=/opt/bin
mkdir -p $INSTALL_DIR
tar -xzf $PACKAGE --strip-components 1 -C $INSTALL_DIR
rm -f $PACKAGE

#---

mkdir -p /etc/bash_completion.d

cat <<EOF >>/etc/bash_completion.d/ruff
eval "\$(ruff generate-shell-completion bash)"
EOF
