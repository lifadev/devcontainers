#!/bin/bash

set -eux

source dev-container-features-test-lib

APPS=(
  docker
  dockerd
)

for APP in "${APPS[@]}"; do
  check "$APP" which "$APP" >/dev/null
done

APPS=(
  buildx
  compose
  ps
)

for APP in "${APPS[@]}"; do
  check "$APP" docker "$APP" >/dev/null
done

check "clean" test ! -e /tmp/package*

reportResults
