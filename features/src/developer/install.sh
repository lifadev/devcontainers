#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

dc_install \
  sudo

groupadd \
  --gid "$GROUP_ID" \
  "$USER_NAME"
useradd \
  --uid "$USER_ID" \
  --gid "$GROUP_ID" \
  --create-home "$USER_NAME" \
  --shell /bin/bash

echo "$USER_NAME" ALL=\(root\) NOPASSWD:ALL >"/etc/sudoers.d/$USER_NAME"
chmod 0440 "/etc/sudoers.d/$USER_NAME"
