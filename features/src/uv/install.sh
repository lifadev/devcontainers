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

#? https://github.com/astral-sh/uv/tags
#? .sha256
PACKAGE_VERSION=0.6.3
case $ARCH in
amd64)
  PACKAGE_URL="https://github.com/astral-sh/uv/releases/download/${PACKAGE_VERSION}/uv-x86_64-unknown-linux-gnu.tar.gz"
  PACKAGE_SUM=b7a37a33d62cb7672716c695226450231e8c02a8eb2b468fa61cd28a8f86eab2
  ;;
arm64)
  PACKAGE_URL="https://github.com/astral-sh/uv/releases/download/${PACKAGE_VERSION}/uv-aarch64-unknown-linux-gnu.tar.gz"
  PACKAGE_SUM=447726788204106ffd8ecc59396fccc75fae7aca998555265b5ea6950b00160c
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

cat <<EOF >>/etc/bash_completion.d/uv
eval "\$(uv generate-shell-completion bash)"
EOF

cat <<EOF >>/etc/bash_completion.d/uvx
eval "\$(uvx --generate-shell-completion bash)"
EOF
