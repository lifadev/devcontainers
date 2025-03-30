#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

export LANG="C.UTF-8"
export DEBIAN_FRONTEND=noninteractive

dc_install \
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
