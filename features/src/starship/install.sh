#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

PACKAGE=/tmp/package.tar.gz
dc_download starship $PACKAGE

INSTALL_DIR=$(dc_mkdir /opt/bin)
tar -xzf $PACKAGE -C "$INSTALL_DIR"

dc_bash_complete starship <<EOF
eval "\$(starship init bash)"
EOF

rm -rf /tmp/package*
