#!/bin/bash

set -eux

if [ "$UID" -ne 0 ]; then
  echo -e "(!) User must be root: $UID"
  exit 1
fi

ARCH="$(dpkg --print-architecture)"
if [ "$ARCH" != 'amd64' ] && [ "$ARCH" != 'arm64' ]; then
  echo "(!) Unsupported architecture: $ARCH"
  exit 1
fi

#---

if command -v python3 >/dev/null 2>&1; then
  #? https://github.com/ipython/ipykernel/tags
  #? https://github.com/matplotlib/ipympl/tags
  #? https://github.com/matplotlib/matplotlib/tags
  #? https://github.com/numpy/numpy/tags
  python3 -m pip install --upgrade \
    "ipykernel==6.29.5" \
    "ipympl==0.9.7" \
    "matplotlib==3.10.1" \
    "numpy==2.2.3"
fi
