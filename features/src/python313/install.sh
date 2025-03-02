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

export LANG="C.UTF-8"

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

#---

#? https://github.com/python/cpython/tags
#? https://github.com/docker-library/python/blob/master/3.13/bookworm/Dockerfile
PACKAGE_VERSION=3.13.2
PACKAGE_URL="https://www.python.org/ftp/python/${PACKAGE_VERSION}/Python-${PACKAGE_VERSION}.tar.xz"
PACKAGE_SUM=d984bcc57cd67caab26f7def42e523b1c015bbc5dc07836cf4f0b63fa159eb56

PACKAGE=/tmp/package.tar.xz
curl -fLsS "$PACKAGE_URL" -o $PACKAGE
echo "$PACKAGE_SUM $PACKAGE" | sha256sum -c

BUILD_DIR=/tmp/python313
mkdir -p $BUILD_DIR
tar -xJf $PACKAGE --strip-components 1 -C $BUILD_DIR
rm -f $PACKAGE

INSTALL_DIR=/opt/python313
mkdir -p $INSTALL_DIR

#? https://docs.python.org/3/using/configure.html
cd $BUILD_DIR
./configure \
  --build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
  --prefix=$INSTALL_DIR \
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
bin=$(readlink -ve $INSTALL_DIR/bin/python3)
dir=$(dirname "$bin")
mkdir -p "/usr/share/gdb/auto-load/$dir"
cp -vL Tools/gdb/libpython.py "/usr/share/gdb/auto-load/$bin-gdb.py"

cd /
rm -rf $BUILD_DIR
find $INSTALL_DIR -depth \
  \( \
  \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
  -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name 'libpython*.a' \) \) \
  \) -exec rm -rf '{}' +

ldconfig

#---

#? https://github.com/pypa/build/tags
#? https://github.com/pypa/pip/tags
#? https://github.com/pypa/setuptools/tags
#? https://github.com/pypa/wheel/tags
python3 -m pip install --upgrade \
  "build==1.2.2.post1" \
  "pip==25.0.1" \
  "setuptools==75.8.2" \
  "wheel==0.45.1"
