#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

PACKAGE=/tmp/package.tar.gz
dc_download jujutsu $PACKAGE

INSTALL_DIR=$(dc_mkdir /opt/bin)
tar --no-anchored -xzf $PACKAGE -C "$INSTALL_DIR" jj

# shellcheck disable=SC2119
dc_bash_complete jujutsu <<EOF
source <(COMPLETE=bash $INSTALL_DIR/jj)
EOF
