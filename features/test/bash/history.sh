#!/bin/bash

set -eux

source dev-container-features-test-lib

BASH_CONFIG_DIR=$(dirname "$HISTFILE")

check "owner" test "$(stat -c %U -- "$BASH_CONFIG_DIR")" = "developer"
check "group" test "$(stat -c %G -- "$BASH_CONFIG_DIR")" = "developer"

reportResults
