#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

if command -v python3 >/dev/null 2>&1; then
  python3 -m pip install --upgrade \
    "ipykernel==$(dc_version ipykernel)" \
    "ipympl==$(dc_version ipympl)" \
    "matplotlib==$(dc_version matplotlib)" \
    "numpy==$(dc_version numpy)"
fi
