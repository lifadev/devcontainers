#!/bin/bash

set -eux

if [[ "$UID" -ne 0 ]]; then
  echo -e "(!) User must be root: $UID"
  exit 1
fi

ARCH="$(dpkg --print-architecture)"
if [[ "$ARCH" != 'amd64' ]] && [[ "$ARCH" != 'arm64' ]]; then
  echo "(!) Unsupported architecture: $ARCH"
  exit 1
fi

dc_install() {
  apt update --quiet
  apt install --yes --no-install-recommends "$@"
  rm -rf /var/lib/apt/lists/*
  return 0
}

dc_mkdir() {
  local target=$1

  mkdir -p "$target"
  echo "$target"

  return 0
}

_dc_package() {
  local name=$1

  local package
  package=$(
    jq -r \
      --arg NAME "$name" \
      '.customizations.manifest.dependencies[] | select(.name == $NAME)' \
      "$(dirname "$0")/devcontainer-feature.json"
  )

  local version
  version=$(jq -r '.version' <<<"$package")
  export VERSION=$version

  echo "$package" | envsubst

  return 0
}

dc_download() {
  local package=$1
  local output=$2

  local artifact
  artifact=$(
    jq -r \
      --arg ARCH "$ARCH" \
      '.artifacts[] | select(.architecture | IN($ARCH, "universal"))' \
      <<<"$(_dc_package "$package")"
  )

  local url
  url=$(jq -r '.url' <<<"$artifact")

  local checksum
  checksum=$(jq -r '.checksum' <<<"$artifact")

  curl -fLsS "$url" -o "$output"
  echo "$checksum $output" | sha256sum -c

  return 0
}

dc_version() {
  local package=$1

  jq -r '.version' <<<"$(_dc_package "$package")"

  return 0
}

dc_bash_complete() {
  local package=$1

  local script
  script=$(cat)

  local target
  target=$(dc_mkdir /etc/bash_completion.d)
  echo "$script" >>"$target/$package"

  return 0
}

dc_bash_config() {
  local package=$1

  local script
  script=$(cat)

  local target
  target=$(dc_mkdir /etc/bashrc.d)
  echo "$script" >>"$target/$package"

  return 0
}

dc_cleanup() {
  rm -rf /tmp/package*
  return 0
}

trap dc_cleanup EXIT HUP INT TERM

dc_install \
  ca-certificates \
  curl \
  gettext-base \
  jq \
  xz-utils \
  unzip
