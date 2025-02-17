#!/bin/bash

set -eux

# region Options

BUILD_VERSION=${BUILD_VERSION:-undefined}
PIP_VERSION=${PIP_VERSION:-undefined}
SETUPTOOLS_VERSION=${SETUPTOOLS_VERSION:-undefined}
WHEEL_VERSION=${WHEEL_VERSION:-undefined}

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

# region Python

apt update --quiet
apt install --yes --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  pkg-config \
  xz-utils \
  \
  libbz2-dev \
  libffi-dev \
  libgdbm-compat-dev \
  libgdbm-dev \
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
  --prefix="$PYTHON_INSTALL_DIR" \
  --enable-loadable-sqlite-extensions \
  --enable-optimizations \
  --enable-option-checking=fatal \
  --enable-shared \
  --with-ensurepip \
  --with-lto

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

#? Enable GDB to load debugging data
#? https://github.com/docker-library/python/pull/701
bin=$(readlink -ve $PYTHON_BIN_DIR/python3)
dir=$(dirname "$bin")
mkdir -p "/usr/share/gdb/auto-load/$dir"
cp -vL Tools/gdb/libpython.py "/usr/share/gdb/auto-load/$bin-gdb.py"

cd /
rm -rf $PACKAGE_BUILD_DIR
find "$PYTHON_INSTALL_DIR" -depth \
  \( \
  \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
  -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name 'libpython*.a' \) \) \
  \) -exec rm -rf '{}' +

ldconfig

export PATH=$PYTHON_BIN_DIR:$PATH

# endregion

# region Package managers

#? https://github.com/pypa/build/tags
#? https://github.com/pypa/pip/tags
#? https://github.com/pypa/setuptools/tags
#? https://github.com/pypa/wheel/tags
python3 -m pip install --upgrade \
  "build==$BUILD_VERSION" \
  "pip==$PIP_VERSION" \
  "setuptools==$SETUPTOOLS_VERSION" \
  "wheel==$WHEEL_VERSION"

# endregion

# endregion
