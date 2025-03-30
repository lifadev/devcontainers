#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

PACKAGE=/tmp/package.zip
dc_download cli $PACKAGE

BUILD_DIR=/tmp/package
unzip -q $PACKAGE -d $BUILD_DIR
rm -f $PACKAGE

BIN_DIR=/opt/bin
INSTALL_DIR=/opt/aws2
$BUILD_DIR/aws/install -i $INSTALL_DIR -b $BIN_DIR
rm -rf $BUILD_DIR

#---

mkdir -p /etc/bash_completion.d

cat <<EOF >>/etc/bash_completion.d/aws2
complete -C '$BIN_DIR/aws_completer' aws
EOF
