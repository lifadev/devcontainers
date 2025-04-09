#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

INSTALL_DIR=$(dc_mkdir /opt/bin)

PACKAGE=/tmp/package.tar.xz
dc_download shellcheck $PACKAGE
tar -xJf $PACKAGE --strip-components 1 -C "$INSTALL_DIR" --wildcards "*/shellcheck"

PACKAGE=/tmp/package
dc_download shfmt $PACKAGE
mv $PACKAGE "$INSTALL_DIR/shfmt"
chmod +x "$INSTALL_DIR/shfmt"

mkdir -p /etc/bashrc.d
cat <<EOF >>/etc/bash.bashrc
if [ -d /etc/bashrc.d ]; then
  for i in /etc/bashrc.d/*; do
    if [ -r "\$i" ]; then
      # shellcheck disable=SC1090
      . "\$i"
    fi
  done
  unset i
fi
EOF
