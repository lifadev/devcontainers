#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

PACKAGE=/tmp/package.tar.gz
dc_download cli $PACKAGE

INSTALL_DIR=$(dc_mkdir /opt/bin)
MATCH=$(tar -tzf $PACKAGE | grep '^.*/bin/gh$' | head -n1)
tar -xzf $PACKAGE -C "$INSTALL_DIR" --strip-components 2 "$MATCH"

dc_bash_complete uv <<EOF
eval "\$(gh completion -s bash)"
EOF
