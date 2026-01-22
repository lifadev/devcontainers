#!/bin/bash

set -eux

source dev-container-features-test-lib

check allowed test "$(sudo echo >/dev/null 2>&1 && echo "expected" || echo "unexpected")" = "expected"
check restricted test "$(sudo ls >/dev/null 2>&1 && echo "unexpected" || echo "expected")" = "expected"

reportResults
