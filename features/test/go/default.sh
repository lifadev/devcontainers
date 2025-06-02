#!/bin/bash

set -eux

source dev-container-features-test-lib

APPS=(
  go
)

for APP in "${APPS[@]}"; do
  check "$APP" which "$APP" >/dev/null
done

TOOLS=(
  dlv
  gomodifytags
  goplay
  gopls
  gotests
  impl
  staticcheck
)

for TOOL in "${TOOLS[@]}"; do
  check "$TOOL" which "$TOOL" >/dev/null
done

check "clean" test ! -e /tmp/package*

reportResults
