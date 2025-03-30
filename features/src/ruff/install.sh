#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

PACKAGE=/tmp/package.tar.gz
dc_download ruff $PACKAGE

INSTALL_DIR=$(dc_mkdir /opt/bin)
tar -xzf $PACKAGE --strip-components 1 -C "$INSTALL_DIR"

dc_bash_complete ruff <<EOF
eval "\$(ruff generate-shell-completion bash)"
EOF

dc_cleanup
