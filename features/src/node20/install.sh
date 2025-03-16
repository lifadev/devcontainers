#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

PACKAGE=/tmp/package.tar.xz
dc_download node $PACKAGE

INSTALL_DIR=$(dc_mkdir /opt/node20)
tar -xJf $PACKAGE --strip-components 1 -C "$INSTALL_DIR"

npm install -g "npm@$(dc_version npm)"

# shellcheck disable=SC2119
dc_bash_complete node20-npm <<EOF
eval "\$($INSTALL_DIR/npm completion)"
EOF

rm -f /tmp/package*
