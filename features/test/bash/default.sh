#!/bin/bash

set -eux

source dev-container-features-test-lib

APPS=(
  shellcheck
  shfmt
)

for APP in "${APPS[@]}"; do
  check "$APP" which "$APP" >/dev/null
done

reportResults
