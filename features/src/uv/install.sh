#!/bin/bash

set -eux

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

apt update --quiet
apt install --yes --no-install-recommends \
  ca-certificates \
  curl
rm -rf /var/lib/apt/lists/*

# region `uv`

#? https://github.com/astral-sh/uv/tags
#? .sha256
PACKAGE_VERSION=0.6.2
case $ARCH in
amd64)
  PACKAGE_URL="https://github.com/astral-sh/uv/releases/download/${PACKAGE_VERSION}/uv-x86_64-unknown-linux-gnu.tar.gz"
  PACKAGE_SUM=37ea31f099678a3bee56f8a757d73551aad43f8025d377a8dde80dd946c1b7f2
  ;;
arm64)
  PACKAGE_URL="https://github.com/astral-sh/uv/releases/download/${PACKAGE_VERSION}/uv-aarch64-unknown-linux-gnu.tar.gz"
  PACKAGE_SUM=ca4c08724764a2b6c8f2173c4e3ca9dcde0d9d328e73b4d725cfb6b17a925eed
  ;;
esac

PACKAGE=/tmp/package.tar.gz
curl -fLsS "$PACKAGE_URL" -o $PACKAGE
echo "$PACKAGE_SUM $PACKAGE" | sha256sum -c
tar -xzf $PACKAGE --strip-components 1 -C $BIN_DIR
rm -f $PACKAGE

# endregion

# endregion

# region Shell integration

mkdir -p /etc/bash_completion.d

cat <<EOF >>/etc/bash_completion.d/uv
eval "\$(uv generate-shell-completion bash)"
EOF

cat <<EOF >>/etc/bash_completion.d/uvx
eval "\$(uvx --generate-shell-completion bash)"
EOF

# endregion
