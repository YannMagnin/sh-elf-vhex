#! /usr/bin/env bash

#---
# Help screen
#---

function help() {
  cat << EOF
Script for the building step of GCC for the Vhex project

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
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
      echo "error: unrecognized argument '$arg', giving up." >&2
      exit 1
  esac
done

#---
# Preliminary checks
#---

_src=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$_src" || exit 1
source ../_utils.sh

if ! test -d ../../_build/gcc || ! test -f ../../_build/gcc/sysroot_info.txt
then
  echo 'error: Are you sure to have built GCC ? it seems that' >&2
  echo '  the build directory is missing...' >&2
  exit 1
fi
prefix_sysroot=$(cat ../../_build/gcc/sysroot_info.txt)


if [[ -f ../../_build/gcc/.fini ]]
then
  echo "$TAG already built, skipping rebuilding"
  exit 0
fi


cd ../../_build/gcc/build || exit 1

#---
# Build GCC stage-1
#---

echo "$TAG Configuring GCC..."

utils_callcmd \
  ../archive/configure                  \
  --prefix="$prefix_sysroot"            \
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

utils_makecmd all-gcc

echo "$TAG Install partial GCC..."

utils_makecmd install-strip-gcc

#---
# Patch the C standar library
#---

# export binaries used to build OpenLibM and fxLibc

export PATH="$PATH:$prefix_sysroot/bin"

echo "$TAG Building Vhex's custom C standard library..."

utils_callcmd \
  git clone https://github.com/YannMagnin/vxLibc.git --depth 1 ../../_vxlibc

../../_vxlibc/scripts/install.sh                   \
  --prefix-sysroot="$prefix_sysroot/sh-elf-vhex/"  \
  --yes                                            \
|| exit 1

#---
# Finish to build GCC
#---

echo "$TAG Compiling libgcc..."

utils_makecmd all-target-libgcc

echo "$TAG Install libgcc..."

utils_makecmd install-strip-target-libgcc

echo "$TAG Compiling libssp..."

utils_makecmd all-target-libssp

echo "$TAG Install libssp..."

utils_makecmd install-strip-target-libssp

echo "$TAG Compiling LTO plugin..."

utils_makecmd all-lto-plugin

echo "$TAG Install LTO plugin..."

utils_makecmd install-strip-lto-plugin

echo "$TAG Compiling libsanitizer..."

utils_makecmd all-target-libsanitizer

echo "$TAG Install libsanitizer..."

utils_makecmd install-strip-target-libsanitizer

#---
# Indicate that the building up is finished
#---

rm -rf ../build
rm -rf ../archive
touch ../.fini
