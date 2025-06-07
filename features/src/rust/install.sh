#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

PACKAGE=/tmp/package.tar.xz
dc_download rust $PACKAGE

SRC_DIR=$(dc_mkdir /tmp/package)
tar -xJf $PACKAGE --strip-components 1 -C "$SRC_DIR"

INSTALL_DIR=$(dc_mkdir /opt/rust)
"$SRC_DIR"/install.sh --prefix="$INSTALL_DIR" --verbose

# shellcheck disable=SC2119
dc_bash_complete cargo <<EOF
$(cat "$INSTALL_DIR"/etc/bash_completion.d/cargo)
EOF

# ---

PACKAGE=/tmp/package.tar.gz
dc_download rust-src $PACKAGE

INSTALL_DIR=$(dc_mkdir /opt/rust/lib/rustlib/src/rust)
tar -xzf $PACKAGE --strip-components 1 -C "$INSTALL_DIR"
