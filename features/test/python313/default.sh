#!/bin/bash

set -eux

source dev-container-features-test-lib

APPS=(
  pip3
  pip3.13
  python3
  python3.13
)

for APP in "${APPS[@]}"; do
  check "$APP" which "$APP" >/dev/null
done

LIBS=(
  build
  bz2
  ctypes
  dbm
  hashlib
  lzma
  pip
  readline
  setuptools
  sqlite3
  ssl
  uuid
  wheel
  zlib
)

for LIB in "${LIBS[@]}"; do
  check "$LIB" python3.13 -c "import $LIB" >/dev/null
done

check "clean" test ! -e /tmp/package*

reportResults
