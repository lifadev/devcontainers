#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

PACKAGE=/tmp/package.tar.gz
dc_download go $PACKAGE

INSTALL_DIR=$(dc_mkdir /opt/go)
tar -xzf $PACKAGE --strip-components 1 -C "$INSTALL_DIR"

export GOPATH=$INSTALL_DIR/vscode
go install "github.com/cweill/gotests/gotests@v$(dc_version gotests)"
go install "github.com/fatih/gomodifytags@v$(dc_version gomodifytags)"
go install "github.com/go-delve/delve/cmd/dlv@v$(dc_version dlv)"
go install "github.com/haya14busa/goplay/cmd/goplay@v$(dc_version goplay)"
go install "github.com/josharian/impl@v$(dc_version impl)"
go install "golang.org/x/tools/gopls@v$(dc_version gopls)"
go install "honnef.co/go/tools/cmd/staticcheck@v$(dc_version staticcheck)"
