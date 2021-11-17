#! /usr/bin/env bash

verbose=false

#
# Help screen
#
help() {
  cat << OEF
Script for the building step of GCC for the Vhex kernel.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
  --verbose             Display extra information during the building step
OEF
  exit 0
}



#
# Parse arguments
#

for arg; do case "$arg" in
  --help | -h)          help;;
  --verbose)            verbose=true;;
  *)
    echo "error: unreconized argument '$arg', giving up." >&2
    exit 1
esac; done



#
# Building step
# @note:
#   We need to build GCC at least two time. This because we want to enable
#  shared version of the libgcc. But, to compile this library, we require
#  building our own standard C library, which require openlibm and the static
#  version of the libgcc.
#
#   To avoid this circular dependency, we shall build the GCC tools with the
#  static version of the libgcc. This will enable us to compile the openlibm,
#  then our custom C standard library. After that, we will rebuild GCC with,
#  this time, the shared version of the libgcc.
#

TAG='<sh-elf-vhex-gcc>'

# Import some helpers

source ../utils.sh

# OpenBSD apparently installs these in /usr/local

extra_args=
if [[ $(uname) == "OpenBSD" ]]; then
  extra_args='--with-gmp=/usr/local --with-mpfr=/usr/local --with-mpc=/usr/local'
fi

# Create the build directory

mkdir -p ../../build/gcc/build
cd ../../build/gcc/build

# Install dependencies
../gcc/contrib/download_prerequisites



#
# Build GCC stage-1
#

echo "$TAG Configuring GCC (stage 1)..."

# GCC does not support 'make uninstall' so we install in this directory and
# later symlink executables to the "real" prefix.

PREFIX="$(pwd)/.."

# Configure GCC stage-1 (force disable shared version of the libgcc)

$quiet ../gcc/configure --prefix=$PREFIX --target=sh-elf-vhex \
      --with-multilib-list=m3,m4-nofpu --enable-languages=c --without-headers \
      --disable-nls --enable-lto --disable-shared $extra_args

echo "$TAG Compiling GCC (stage 1) (usually 10-20 minutes)..."

$quiet $make_cmd -j"$cores" all-gcc

echo "$TAG Install GCC (stage 1)..."

$quiet $make_cmd -j"$cores" install-strip-gcc

echo "$TAG Compiling libgcc (stage 1)..."

$quiet $make_cmd -j"$cores" all-target-libgcc

echo "$TAG Install libgcc (stage 1)..."

$quiet $make_cmd -j"$cores" install-strip-target-libgcc



#
# Patch the C standar library
#

# Export binaries used to build OpenLibM and fxLibc

cd ..

export PATH="$PATH:$(pwd)/bin"
export PATH="$PATH:$(pwd)/sh-elf-vhex/bin"

cd ..

echo "$TAG Building Vhex's custom C standard library..."

# Install OpenLibM

rm -rf OpenLibm
$quiet git clone https://gitea.planet-casio.com/Lephenixnoir/OpenLibm.git --depth=1
cd OpenLibm

# Get installation path

LIP=$(sh-elf-vhex-gcc --print-search-dirs | grep install | sed 's/install: //')

# Build

$quiet $make_cmd USEGCC=1 ARCH=sh3eb TOOLPREFIX=sh-elf-vhex- \
  CC=sh-elf-vhex-gcc AR=sh-elf-vhex-ar \
  libdir="$LIP" includedir="$LIP/include"

# Install (needed by fxlibc)

$quiet $make_cmd USEGCC=1 ARCH=sh3eb TOOLPREFIX=sh-elf-vhex- \
  CC=sh-elf-vhex-gcc AR=sh-elf-vhex-ar \
  libdir="$LIP" includedir="$LIP/include" \
  install-static install-headers

cd ..

# Build Vhex custom C standard library

rm -rf fxlibc
$quiet git clone https://gitea.planet-casio.com/Vhex-Kernel-Core/fxlibc.git
cd fxlibc
$quiet git checkout dev

$quiet cmake -DFXLIBC_TARGET=vhex-sh -B build-vhex \
    -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-vhex.cmake \
    -DCMAKE_C_COMPILER_WORKS=1 -DCMAKE_INSTALL_PREFIX="$LIP"

cd build-vhex

$quiet $make_cmd

cd ../..


#
# Build GCC stage-2
#

echo "$TAG Configuring GCC (stage 2)..."

cd gcc

# Remove stage-1 compilation part

rm -rf $(ls | grep -v gcc | grep -v sh-elf-vhex)

# Recreate the build directory

mkdir -p build
cd build

# Configure GCC for the stage-2 (force enable shared version of libgcc)

$quiet ../gcc/configure --prefix=$PREFIX --target=sh-elf-vhex \
      --with-multilib-list=m3,m4-nofpu --enable-languages=c --without-headers \
      --disable-nls --enable-lto $extra_args

echo "$TAG Compiling GCC (stage 2) (usually 10-20 minutes)..."

$quiet $make_cmd -j"$cores" all-gcc

echo "$TAG Install GCC (stage 2)..."

$quiet $make_cmd -j"$cores" install-strip-gcc

#
# Patch the generation of the shared version of the libgcc which require a C
# standard library.
#

echo "$TAG Install C standar library..."

# Re-install openlibm

cd ../../OpenLibm

$quiet $make_cmd USEGCC=1 ARCH=sh3eb TOOLPREFIX=sh-elf-vhex- \
  CC=sh-elf-vhex-gcc AR=sh-elf-vhex-ar \
  libdir="$LIP" includedir="$LIP/include" \
  install-static install-headers

# Install the C standard library

cd ../fxlibc/build-vhex
$quiet $make_cmd install

# Generate the shared version of libgcc

cd ../../gcc/build

# It seems that the generation of the shared libgcc search the
# libc in a non-conventional (?) path

rm -rf $(pwd)/../sh-elf-vhex/lib
ln -sf $LIP/lib $(pwd)/../sh-elf-vhex/lib

echo "$TAG Compiling libgcc (stage 2)..."

$quiet $make_cmd -j"$cores" all-target-libgcc

echo "$TAG Install libgcc (stage 2)..."

$quiet $make_cmd -j"$cores" install-strip-target-libgcc
exit 0
