#!/bin/bash

set -eux

source dev-container-features-test-lib
OK="ok" KO="ko"

ALLOWED=(
  https://api.github.com/
  https://registry.npmjs.org/
)

for URL in "${ALLOWED[@]}"; do
  check "allowed: $URL" test "$(curl --connect-timeout 5 "$URL" >/dev/null 2>&1 && echo $OK || echo $KO)" = $OK
done

check restricted test "$(curl --connect-timeout 5 https://example.com >/dev/null 2>&1 && echo $KO || echo $OK)" = $OK

check "clean" test ! -e /tmp/package*

reportResults
