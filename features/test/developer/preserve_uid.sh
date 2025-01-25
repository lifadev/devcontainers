#!/bin/bash

set -eux

source dev-container-features-test-lib

check user-name test "$(id -un)" = "developer"
check group-name test "$(id -gn)" = "developer"

check user-id test "$(id -u)" = "1000"
check group-id test "$(id -g)" = "1000"

reportResults
