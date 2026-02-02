#!/bin/bash

set -eux

export PATH=/opt/bin:$PATH

(dockerd >/var/log/dockerd.log 2>&1) &

until docker network inspect bridge >/dev/null 2>&1; do sleep 0.2; done
