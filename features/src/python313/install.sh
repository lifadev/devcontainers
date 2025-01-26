#!/bin/bash

set -eux

# region Options

PIP_VERSION=${PIP_VERSION:-undefined}

# endregion

# region Prerequisites

if [ "$UID" -ne 0 ]; then
  echo -e "(!) User must be root: $UID"
  exit 1
fi

ARCH="$(dpkg --print-architecture)"
if [ "$ARCH" != 'amd64' ] && [ "$ARCH" != 'arm64' ]; then
  echo "(!) Unsupported architecture: $ARCH"
  exit 1
fi

# endregion

# region Installations

# region `python`

apt update --quiet
apt install --yes --no-install-recommends \
  libbz2-dev \
  libffi-dev \
  liblzma-dev \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  uuid-dev \
  zlib1g-dev
rm -rf /var/lib/apt/lists/*

#? https://github.com/python/cpython/tags
#? https://github.com/docker-library/python/blob/master/3.13/bookworm/Dockerfile
PACKAGE_VERSION=3.13.1
PACKAGE_URL="https://www.python.org/ftp/python/${PACKAGE_VERSION}/Python-${PACKAGE_VERSION}.tar.xz"
PACKAGE_SUM=9cf9427bee9e2242e3877dd0f6b641c1853ca461f39d6503ce260a59c80bf0d9

PACKAGE=/tmp/package.tar.xz
curl -fLsS "$PACKAGE_URL" -o $PACKAGE
echo "$PACKAGE_SUM $PACKAGE" | sha256sum -c

PACKAGE_BUILD_DIR=/tmp/python313
mkdir -p $PACKAGE_BUILD_DIR
tar -xJf $PACKAGE --strip-components 1 -C $PACKAGE_BUILD_DIR
rm -f $PACKAGE

#? https://docs.python.org/3/using/configure.html
cd $PACKAGE_BUILD_DIR
./configure \
  --build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
  --enable-loadable-sqlite-extensions \
  --enable-optimizations \
  --enable-option-checking=fatal \
  --enable-shared \
  --prefix="$PYTHON_INSTALL_DIR" \
  --with-ensurepip \
  --with-lto \
  --with-readline=readline

EXTRA_CFLAGS="$(dpkg-buildflags --get CFLAGS)"
LDFLAGS="$(dpkg-buildflags --get LDFLAGS)"

#? https://docs.python.org/3.12/howto/perf_profiling.html
#? https://github.com/docker-library/python/pull/1000#issuecomment-2597021615
#? ARCH != i686-linux-gnu
EXTRA_CFLAGS="${EXTRA_CFLAGS:-} -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer"
make -j "$(nproc)" \
  "EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
  "LDFLAGS=${LDFLAGS:-}"

#? https://github.com/docker-library/python/issues/784
#? Prevent accidental usage of a system installed libpython
rm python
make -j "$(nproc)" \
  "EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
  "LDFLAGS=${LDFLAGS:--Wl},-rpath='\$\$ORIGIN/../lib'" \
  python
make install

cd /
rm -rf $PACKAGE_BUILD_DIR
find "$PYTHON_INSTALL_DIR" -depth \
  \( \
  \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
  -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name 'libpython*.a' \) \) \
  \) -exec rm -rf '{}' +

ldconfig

# endregion

# endregion
