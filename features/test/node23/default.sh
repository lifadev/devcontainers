#!/bin/bash

set -eux

source dev-container-features-test-lib

APPS=(
  node
  npm
)

for APP in "${APPS[@]}"; do
  check "$APP" which "$APP" >/dev/null
done

reportResults
