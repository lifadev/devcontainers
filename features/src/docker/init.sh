#!/bin/bash

set -eux

export PATH=/opt/bin:$PATH

(dockerd -H "$DOCKER_HOST" >/var/log/dockerd.log 2>&1) &
