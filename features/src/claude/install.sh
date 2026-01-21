#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

dc_mkdir "$CLAUDE_CONFIG_DIR"
chown "$_REMOTE_USER:$_REMOTE_USER" "$CLAUDE_CONFIG_DIR"

curl -fLsS https://claude.ai/install.sh |
  sudo -H -u "$_REMOTE_USER" bash -s "$(dc_version cli)"
