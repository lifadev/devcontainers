#!/bin/bash

set -eux

export PATH=/opt/bin:$PATH

(dockerd >/var/log/dockerd.log 2>&1) &
