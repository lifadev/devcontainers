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

dc_install() {
  apt update --quiet
  apt install --yes --no-install-recommends "$@"
  rm -rf /var/lib/apt/lists/*
}

dc_mkdir() {
  TARGET=$1

  mkdir -p "$TARGET"
  echo "$TARGET"
}

_dc_package() {
  local NAME=$1

  local PACKAGE
  PACKAGE="$(jq -r \
    --arg NAME "$NAME" \
    '.[] | select(.name == $NAME)' \
    "$(dirname "$0")/dependencies.json")"

  local VERSION
  VERSION=$(jq -r '.version' <<<"$PACKAGE")
  export VERSION

  echo "$PACKAGE" | envsubst
}

dc_download() {
  local PACKAGE=$1
  local OUTPUT=$2

  local ARTIFACT
  ARTIFACT=$(jq -r \
    --arg ARCH "$ARCH" \
    '.artifacts[] | select(.architecture | IN($ARCH, "universal"))' \
    <<<"$(_dc_package "$PACKAGE")")

  local URL
  URL=$(jq -r '.url' <<<"$ARTIFACT")

  local CHECKSUM
  CHECKSUM=$(jq -r '.checksum' <<<"$ARTIFACT")

  curl -fLsS "$URL" -o "$OUTPUT"
  echo "$CHECKSUM $OUTPUT" | sha256sum -c
}

dc_version() {
  local PACKAGE=$1

  jq -r '.version' <<<"$(_dc_package "$PACKAGE")"
}

dc_bash_complete() {
  local PACKAGE=$1

  local SCRIPT
  SCRIPT=$(cat)

  TARGET=$(dc_mkdir /etc/bash_completion.d)
  echo "$SCRIPT" >>"$TARGET/$PACKAGE"
}

dc_bash_config() {
  local PACKAGE=$1

  local SCRIPT
  SCRIPT=$(cat)

  TARGET=$(dc_mkdir /etc/bashrc.d)
  echo "$SCRIPT" >>"$TARGET/$PACKAGE"
}

dc_cleanup() {
  rm -rf /tmp/package*
}

dc_install \
  ca-certificates \
  curl \
  gettext-base \
  jq \
  xz-utils \
  unzip
