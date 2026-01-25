#!/bin/bash

set -eux

source dev-container-features-test-lib
OK="ok" KO="ko"

check allowed test "$(sudo echo >/dev/null 2>&1 && echo $OK || echo $KO)" = $OK
check restricted test "$(sudo ls >/dev/null 2>&1 && echo $KO || echo $OK)" = $OK

reportResults
