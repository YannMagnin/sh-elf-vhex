#! /usr/bin/env bash

verbose=false

#---
# Help screen
#---
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



#---
# Parse arguments
#---

for arg; do case "$arg" in
  --help | -h)          help;;
  --verbose)            verbose=true;;
  *)
    echo "error: unreconized argument '$arg', giving up." >&2
    exit 1
esac; done


# Import some helpers

source ../utils.sh

#---
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
#---

TAG='<sh-elf-vhex-gcc>'
SYSROOT="$(get_sysroot)"

# Avoid rebuilds and error

if [[ -f ../../build/gcc/.fini ]]; then
  echo "$TAG already build, skipping rebuild"
  exit 0
fi

if [[ ! -d ../../build/gcc ]]; then
  echo "error: Are you sure to have built GCC ? it seems that" >&2
  echo "  the build directory is missing..." >&2
  exit 1
fi

cd ../../build/gcc/build




#---
# Build GCC stage-1
#---

echo "$TAG Configuring GCC (stage 1)..."

# Configure GCC stage-1 (force disable shared version of the libgcc)

$quiet ../gcc/configure                 \
  --prefix="$SYSROOT"                   \
  --target='sh-elf-vhex'                \
  --program-prefix="sh-elf-vhex-"       \
  --with-multilib-list='m3,m4-nofpu'    \
  --enable-languages='c'                \
  --without-headers                     \
  --enable-lto                          \
  --enable-libssp                       \
  --enable-libsanitizer                 \
  --enable-shared                       \
  --disable-threads                     \
  --disable-default-ssp                 \
  --disable-nls                         \
  $extra_args

echo "$TAG Compiling GCC (usually 10-20 minutes)..."

$quiet $make_cmd -j"$cores" all-gcc

echo "$TAG Install GCC..."

$quiet $make_cmd -j"$cores" install-strip-gcc




#---
# Patch the C standar library
#---

# export binaries used to build OpenLibM and fxLibc
# also export sysroot for the fxlibc build / install steps

export PATH="$PATH:$SYSROOT/bin"
export VXSDK_COMPILER_SYSROOT="$SYSROOT/sh-elf-vhex"
export VXSDK_COMPILER_CIRCULAR_BUILD_WORKAROUND="true"

echo "$TAG Building Vhex's custom C standard library..."

$quiet vxsdk pkg clone fxlibc@dev -o ../fxlibc --yes
$quiet vxsdk -vvv build-superh ../fxlibc --verbose




#---
# Finish to build GCC
#---

echo "$TAG Compiling libgcc..."

$quiet $make_cmd -j"$cores" all-target-libgcc

echo "$TAG Install libgcc..."

$quiet $make_cmd -j"$cores" install-strip-target-libgcc

echo "$TAG Compiling libssp..."

$quiet $make_cmd -j"$cores" all-target-libssp

echo "$TAG Install libssp..."

$quiet $make_cmd -j"$cores" install-strip-target-libssp

echo "$TAG Compiling LTO plugin..."

$quiet $make_cmd -j"$cores" all-lto-plugin

echo "$TAG Install LTO plugin..."

$quiet $make_cmd -j"$cores" install-strip-lto-plugin

echo "$TAG Compiling libsanitizer..."

$quiet $make_cmd -j"$cores" all-target-libsanitizer

echo "$TAG Install libsanitizer..."

$quiet $make_cmd -j"$cores" install-strip-target-libsanitizer


#---
# Indicate that the build is finished
#---

touch ../.fini
exit 0
