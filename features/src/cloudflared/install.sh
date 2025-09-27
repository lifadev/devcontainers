#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

PACKAGE=/tmp/package
dc_download cli $PACKAGE

INSTALL_DIR=$(dc_mkdir /opt/bin)
mv $PACKAGE "$INSTALL_DIR/cloudflared"
chmod +x "$INSTALL_DIR/cloudflared"
