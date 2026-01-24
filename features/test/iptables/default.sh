#!/bin/bash

set -eux

source dev-container-features-test-lib

ALLOWED=(
  https://api.github.com/
  http://registry.npmjs.org/
)

for URL in "${ALLOWED[@]}"; do
  check "allowed: $URL" test "$(curl --connect-timeout 5 "$URL" >/dev/null 2>&1 && echo "expected" || echo "unexpected")" = "expected"
done

check restricted test "$(curl --connect-timeout 5 https://example.com >/dev/null 2>&1 && echo "unexpected" || echo "expected")" = "expected"

reportResults
