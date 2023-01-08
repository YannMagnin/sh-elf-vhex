#! /usr/bin/env bash

verbose=false
cache=false
prefix=

#---
# Help screen
#---
help() {
  cat << OEF
Script for the installation step of binutils/GCC tools for the Vhex kernel.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
  --cache               Keep the build and the sources directory
  --verbose             Display extra information during the installation step
  --prefix=<PREFIX>     Installation prefix
OEF
  exit 0
}




#---
# Parse arguments
#---

[[ $# -eq 0 ]] && help

for arg; do case "$arg" in
  --help | -h)          help;;
  --verbose)            verbose=true;;
  --cache)              cache=true;;
  --prefix=*)           prefix=${arg#*=};;
  *)
    echo "error: unreconized argument '$arg', giving up." >&2
    exit 1
esac; done




#---
# Installation step
#---

source ../scripts/utils.sh

TAG='<sh-elf-vhex>'
PREFIX="$prefix"
SYSROOT="$(get_sysroot)"

# Check that all tools has been generated

existing_gcc="$SYSROOT/bin/sh-elf-vhex-gcc"

if [[ ! -f "$existing_gcc" ]]; then
  echo "error: Are you sure to have built sh-elf-vhex ? it seems that" >&2
  echo "  the 'as' tool is missing..." >&2
  exit 1
fi

# Cleanup build files

if [[ "$cache" == 'false' ]]; then
  echo "$TAG Cleaning up build files..."
  rm -rf ../../build
fi




#---
# Symbolic link executables to $PREFIX
#---

echo "$TAG Symlinking binaries..."

cd "$SYSROOT/bin"

mkdir -p "$PREFIX"
for x in *; do
  ln -sf "$SYSROOT/bin/$x" "$PREFIX/$x"
done
