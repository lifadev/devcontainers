#!/bin/bash

set -eux

source dev-container-features-test-lib

APPS=(
  bzip2
  cloc
  cmake
  curl
  dialog
  direnv
  dirmngr
  dot
  g++
  gcc
  git
  gpg
  groff
  htop
  ip
  jq
  killall
  less
  make
  man
  ncdu
  ping
  ps
  pwgen
  rg
  rsync
  socat
  sponge
  ssh
  strace
  sudo
  tree
  unzip
  uuid
  vim
  wget
  xz
  zip
)

for APP in "${APPS[@]}"; do
  check "$APP" which "$APP" >/dev/null
done

reportResults
