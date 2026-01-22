#!/bin/bash

set -eux

source dev-container-features-test-lib

check "owner" test "$(stat -c %U -- "$HISTFILE")" = "developer"
check "group" test "$(stat -c %G -- "$HISTFILE")" = "developer"

reportResults
