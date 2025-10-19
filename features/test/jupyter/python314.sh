#!/bin/bash

set -eux

source dev-container-features-test-lib

LIBS=(
  ipykernel
  ipympl
  matplotlib
  numpy
)

for LIB in "${LIBS[@]}"; do
  check "$LIB" python3.14 -c "import $LIB" >/dev/null
done

check "clean" test ! -e /tmp/package*

reportResults
