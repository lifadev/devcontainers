#!/bin/bash

set -eux

source dev-container-features-test-lib

LIBS=(
  ipykernel
)

for LIB in "${LIBS[@]}"; do
  check "$LIB" python3.13 -c "import $LIB" >/dev/null
done

check "clean" test ! -e /tmp/package*

reportResults
