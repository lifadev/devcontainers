#!/bin/bash

set -eux

source dev-container-features-test-lib

APPS=(
  pip3
  pip3.14
  python3
  python3.14
)

for APP in "${APPS[@]}"; do
  check "$APP" which "$APP" >/dev/null
done

LIBS=(
  build
  bz2
  compression.zstd
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
  check "$LIB" python3.14 -c "import $LIB" >/dev/null
done

check "clean" test ! -e /tmp/package*

reportResults
