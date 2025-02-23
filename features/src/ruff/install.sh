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

# region `ruff`

#? https://github.com/astral-sh/ruff/tags
#? .sha256
PACKAGE_VERSION=0.9.7
case $ARCH in
amd64)
  PACKAGE_URL="https://github.com/astral-sh/ruff/releases/download/${PACKAGE_VERSION}/ruff-x86_64-unknown-linux-gnu.tar.gz"
  PACKAGE_SUM=902f9ed51f13ed04eb3dc855af99d70e682846c538521a1b2c1b04c170bb5a7d
  ;;
arm64)
  PACKAGE_URL="https://github.com/astral-sh/ruff/releases/download/${PACKAGE_VERSION}/ruff-aarch64-unknown-linux-gnu.tar.gz"
  PACKAGE_SUM=95d2a031a3de3ea5ce99febcbb6891781ebb430213115c1f729578db83109416
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

cat <<EOF >>/etc/bash_completion.d/ruff
eval "\$(ruff generate-shell-completion bash)"
EOF

# endregion
