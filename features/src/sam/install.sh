#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

PACKAGE=/tmp/package.zip
dc_download sam $PACKAGE

BUILD_DIR=/tmp/package
unzip $PACKAGE -d $BUILD_DIR

BIN_DIR=/opt/bin
INSTALL_DIR=/opt/sam
$BUILD_DIR/install -i $INSTALL_DIR -b $BIN_DIR

#? https://github.com/aws/aws-sam-cli/issues/6842

rm -rf /tmp/package*
