#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

dc_mkdir "$CODEX_HOME"
chown "$_REMOTE_USER:$_REMOTE_USER" "$CODEX_HOME"

PACKAGE=/tmp/package.tar.gz
dc_download cli $PACKAGE

INSTALL_DIR=$(dc_mkdir /opt/bin)
tar -xzf $PACKAGE -C "$INSTALL_DIR"
mv "$INSTALL_DIR"/codex-*-unknown-linux-gnu "$INSTALL_DIR"/codex

dc_bash_complete codex <<EOF
eval "\$($INSTALL_DIR/codex completion bash)"
EOF
