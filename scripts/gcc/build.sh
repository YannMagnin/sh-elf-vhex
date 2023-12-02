#! /usr/bin/env bash

#---
# Help screen
#---

function help() {
  cat << EOF
Script for the building step of GCC for the Vhex kernel.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
  --verbose             Display extra information during the building step
EOF
  exit 0
}

#---
# Parse arguments
#---

for arg;
  do case "$arg" in
    --help | -h) help;;
    *)
      echo "error: unreconized argument '$arg', giving up." >&2
      exit 1
  esac
done

#---
# Building step
# @note:
#   We need to build GCC at least two time. This because we want to enable
#  shared version of the libgcc. But, to compile this library, we require
#  building our own standard C library, which require openlibm and the
#  static version of the libgcc.
#
#   To avoid this circular dependency, we shall build the GCC tools with the
#  static version of the libgcc. This will enable us to compile the
#  openlibm, then our custom C standard library. After that, we will
#  rebuild GCC with, this time, the shared version of the libgcc.
#---

_src=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$_src/../_utils.sh"

TAG='<sh-elf-vhex-gcc>'
SYSROOT=$(utils_get_env 'VHEX_PREFIX_SYSROOT' 'sysroot')

# Avoid rebuilds and error

if [[ -f ../../build/gcc/.fini ]]
then
  echo "$TAG already build, skipping rebuild"
  exit 0
fi

if [[ ! -d ../../build/gcc ]]
then
  echo 'error: Are you sure to have built GCC ? it seems that' >&2
  echo '  the build directory is missing...' >&2
  exit 1
fi

cd ../../build/gcc/build || exit 1

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
  --disable-nls

echo "$TAG Compiling GCC (usually 10-20 minutes)..."

$quiet $make_cmd -j"$cores" all-gcc

echo "$TAG Install GCC..."

$quiet $make_cmd -j"$cores" install-strip-gcc

#---
# Patch the C standar library
#---

# export binaries used to build OpenLibM and fxLibc

export PATH="$PATH:$SYSROOT/bin"

echo "$TAG Building Vhex's custom C standard library..."
echo 'Not implemented yet'
exit 1

# (todo) : clone the vxlibc in local
# (todo) : build
# (todo) : install

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
