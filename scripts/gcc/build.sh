#! /usr/bin/env bash

verbose=false

read -n 1 -p 'wait user key....' _test

#
# Help screen
#
help()
{
  cat << OEF
Building helper script for the configuration step of the binutils build for the
Vhex kernel project.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
  --verbose             Display extra information during the building step
OEF
  exit 0
}



#
# Parse argument
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
#   We need to build GCC a least two time. This because we whant to enable
#  shared version of the libgcc. But, to compile the librarie, we need to build
#  our own standard C librarie, which required openlibm and the libgcc.
#
#   To avoid this, we will configure and build the GCC tools and the static
#  libgcc. This will enable us to compile the openlibm, then our libc. After
#  that we will anable to build the shared version of the libgcc.
#



## Get external information before starting the building step

# verbose tag
TAG='<sh-elf-vhex-gcc>'

# import utility
source ../util.sh

# Number of processor cores
[[ $(uname) == "OpenBSD" ]] && cores=$(sysctl -n hw.ncpu) || cores=$(nproc)

# check macos make utility
[[ $(command -v gmake >/dev/null 2>&1) ]] && make_cmd=gmake || make_cmd=make

# check quiet build
[[ "$verbose" == "true" ]] && quiet='' || quiet='run_quietly giteapc-build.log'

# OpenBSD apparently installs these in /usr/local
extra_args=
if [[ $(uname) == "OpenBSD" ]]; then
  extra_args="--with-gmp=/usr/local --with-mpfr=/usr/local --with-mpc=/usr/local"
fi



## create the building directory

mkdir -p ../../build/gcc/build
cd ../../build/gcc/build


## first configuration

echo "$TAG Configuring GCC (stage 1)..."

# Configure. GCC does not support make uninstall so we install in this
# directory and later symlink executables to $PREFIX/bin.

PREFIX="$(pwd)/.."

$quiet ../gcc/configure --prefix=$PREFIX --target=sh-elf-vhex \
      --with-multilib-list=m3,m4-nofpu --enable-languages=c --without-headers \
      --disable-nls --enable-lto --disable-shared $extra_args



## first build

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

# export binary

cd ..

export PATH="$PATH:$(pwd)/bin"
export PATH="$PATH:$(pwd)/sh-elf-vhex/bin"

cd ..

## Install OpenLibM

echo "$TAG Install OpenLibM..."

rm -rf OpenLibm
$quiet git clone https://gitea.planet-casio.com/Lephenixnoir/OpenLibm.git --depth=1
cd OpenLibm

# get installation path
LIP=$(sh-elf-vhex-gcc --print-search-dirs | grep install | sed 's/install: //')

# build
$quiet $make_cmd USEGCC=1 ARCH=sh3eb TOOLPREFIX=sh-elf-vhex- \
  CC=sh-elf-vhex-gcc AR=sh-elf-vhex-ar \
  libdir="$LIP" includedir="$LIP/include"

# install
$quiet $make_cmd USEGCC=1 ARCH=sh3eb TOOLPREFIX=sh-elf-vhex- \
  CC=sh-elf-vhex-gcc AR=sh-elf-vhex-ar \
  libdir="$LIP" includedir="$LIP/include" \
  install-static install-headers

cd ..


echo "$TAG Patch the standard library..."

rm -rf fxlibc
git clone https://gitea.planet-casio.com/Vhex-Kernel-Core/fxlibc.git
cd fxlibc
git checkout dev

$quiet cmake -DFXLIBC_TARGET=vhex-sh -B build-vhex \
    -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-vhex.cmake \
    -DCMAKE_C_COMPILER_WORKS=1 -DCMAKE_INSTALL_PREFIX="$LIP"

cd build-vhex

$quiet $make_cmd

cd ../..


#
# Build the GCC state-2
#

echo "$TAG Configuring GCC (stage 2)..."

cd gcc

## remove stage 1 compilation part

rm -rf $(ls | grep -v gcc | grep -v sh-elf-vhex)

## build

mkdir -p build
cd build

$quiet ../gcc/configure --prefix=$PREFIX --target=sh-elf-vhex \
      --with-multilib-list=m3,m4-nofpu --enable-languages=c --without-headers \
      --disable-nls --enable-lto $extra_args

echo "$TAG Compiling GCC (stage 2) (usually 10-20 minutes)..."

$quiet $make_cmd -j"$cores" all-gcc

echo "$TAG Install GCC (stage 2)..."

$quiet $make_cmd -j"$cores" install-strip-gcc

## libc patch

echo "$TAG Install C standar library..."

cd ../../OpenLibm
echo " - OpenLibm"
$quiet $make_cmd USEGCC=1 ARCH=sh3eb TOOLPREFIX=sh-elf-vhex- \
  CC=sh-elf-vhex-gcc AR=sh-elf-vhex-ar \
  libdir="$LIP" includedir="$LIP/include" \
  install-static install-headers

cd ../fxlibc/build-vhex
echo " - FxLibC"
$quiet $make_cmd install



cd ../../gcc/build

# it seems that the generation of the shared libgcc search the
# libc in a non-conventional path

rm -rf $(pwd)/../sh-elf-vhex/lib
ln -sf $LIP/lib $(pwd)/../sh-elf-vhex/lib

echo "$TAG Compiling libgcc (stage 2)..."

$quiet $make_cmd -j"$cores" all-target-libgcc

echo "$TAG Install libgcc (stage 2)..."

$quiet $make_cmd -j"$cores" install-strip-target-libgcc



exit 0
