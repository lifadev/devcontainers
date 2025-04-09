#!/bin/bash

set -eux

# shellcheck source=../../lib/install.sh
source dev-container-features-install-lib

#? https://github.com/docker-library/python/blob/master/3.13/bookworm/Dockerfile

export LANG="C.UTF-8"
dc_install \
  build-essential \
  pkg-config \
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

PACKAGE=/tmp/package.tar.xz
dc_download python $PACKAGE

BUILD_DIR=$(dc_mkdir /tmp/python313)
tar -xJf $PACKAGE --strip-components 1 -C "$BUILD_DIR"

INSTALL_DIR=$(dc_mkdir /opt/python313)

#? https://docs.python.org/3/using/configure.html
cd "$BUILD_DIR"
./configure \
  --build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
  --prefix="$INSTALL_DIR" \
  --enable-loadable-sqlite-extensions \
  --enable-optimizations \
  --enable-option-checking=fatal \
  --enable-shared \
  --with-ensurepip \
  --with-lto

EXTRA_CFLAGS=$(dpkg-buildflags --get CFLAGS)
LDFLAGS=$(dpkg-buildflags --get LDFLAGS)

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
bin=$(readlink -ve "$INSTALL_DIR/bin/python3")
dir=$(dirname "$bin")
mkdir -p "/usr/share/gdb/auto-load/$dir"
cp -vL Tools/gdb/libpython.py "/usr/share/gdb/auto-load/$bin-gdb.py"

cd -
find "$INSTALL_DIR" -depth \
  \( \
  \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
  -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name 'libpython*.a' \) \) \
  \) -exec rm -rf '{}' +

ldconfig

python3 -m pip install --upgrade \
  "build==$(dc_version build)" \
  "pip==$(dc_version pip)" \
  "setuptools==$(dc_version setuptools)" \
  "wheel==$(dc_version wheel)"
