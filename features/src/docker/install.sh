#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

dc_install \
  iptables

INIT_DIR=$(dc_mkdir /opt/init)
cp init.sh "$INIT_DIR/docker.sh"
chmod 0550 "$INIT_DIR/docker.sh"

PACKAGE=/tmp/package.tgz
dc_download cli $PACKAGE

INSTALL_DIR=$(dc_mkdir /opt/bin)
tar -xzf $PACKAGE --strip-components 1 -C "$INSTALL_DIR"

dc_bash_complete docker <<EOF
eval "\$($INSTALL_DIR/docker completion bash)"
EOF

PLUGINS_DIR=$(dc_mkdir /usr/local/libexec/docker/cli-plugins)

PLUGIN=$PLUGINS_DIR/docker-buildx
dc_download buildx "$PLUGIN"
chmod +x "$PLUGIN"

PLUGIN=$PLUGINS_DIR/docker-compose
dc_download compose "$PLUGIN"
chmod +x "$PLUGIN"

groupadd docker
usermod --append \
  --groups docker \
  "$_REMOTE_USER"
