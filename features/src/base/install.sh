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

#? https://hub.docker.com/_/debian/

export DEBIAN_FRONTEND=noninteractive

apt update --quiet
apt upgrade --yes
apt install --yes --no-install-recommends \
  apt-transport-https \
  apt-utils \
  bash-completion \
  build-essential \
  bzip2 \
  ca-certificates \
  cloc \
  cmake \
  curl \
  dialog \
  direnv \
  dirmngr \
  g++ \
  gcc \
  git \
  gnupg2 \
  graphviz \
  groff \
  htop \
  iproute2 \
  iputils-ping \
  jq \
  less \
  locales \
  lsb-release \
  lsof \
  make \
  man-db \
  manpages \
  manpages-dev \
  moreutils \
  ncdu \
  openssh-client \
  pkg-config \
  procps \
  psmisc \
  pwgen \
  ripgrep \
  rsync \
  socat \
  stow \
  strace \
  sudo \
  tree \
  unzip \
  uuid \
  vim \
  wget \
  xz-utils \
  zip
rm -rf /var/lib/apt/lists/*

# endregion
