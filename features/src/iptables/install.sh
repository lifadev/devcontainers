#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

dc_install \
  aggregate \
  dnsutils \
  iproute2 \
  ipset \
  iptables

INIT_DIR=$(dc_mkdir /opt/init)
cp init.sh "$INIT_DIR/iptables.sh"
chmod 0550 "$INIT_DIR/iptables.sh"
