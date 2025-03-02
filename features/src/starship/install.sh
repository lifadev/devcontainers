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

#? https://github.com/starship/starship/tags
#? .sha256
PACKAGE_VERSION=1.22.1
case $ARCH in
amd64)
  PACKAGE_URL="https://github.com/starship/starship/releases/download/v${PACKAGE_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz"
  PACKAGE_SUM=e57db6f6497ee8a426c5e77b4d6f5c50734d3e9cca7a18a8aef46730505a3ae7
  ;;
arm64)
  PACKAGE_URL="https://github.com/starship/starship/releases/download/v${PACKAGE_VERSION}/starship-aarch64-unknown-linux-musl.tar.gz"
  PACKAGE_SUM=b82edd21060f3ed112460442c48a3a9545c8dbf3b564154441f4e6b58eacc387
  ;;
esac

PACKAGE=/tmp/package.tar.gz
curl -fLsS "$PACKAGE_URL" -o $PACKAGE
echo "$PACKAGE_SUM $PACKAGE" | sha256sum -c

INSTALL_DIR=/opt/bin
mkdir -p $INSTALL_DIR
tar -xzf $PACKAGE -C $INSTALL_DIR
rm -f $PACKAGE

#---

mkdir -p /etc/bashrc.d

cat <<EOF >>/etc/bashrc.d/starship
eval "\$(starship init bash)"
EOF
