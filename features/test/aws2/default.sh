#!/bin/bash

set -eux

source dev-container-features-test-lib

APPS=(
  aws
  aws_completer
)

for APP in "${APPS[@]}"; do
  check "$APP" which "$APP" >/dev/null
done

check "clean" test ! -e /tmp/package*
check "clean" test ! -e /tmp/aws*

reportResults
