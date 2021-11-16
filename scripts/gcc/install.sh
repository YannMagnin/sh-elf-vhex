#! /usr/bin/env bash

verbose=false
cache=false
prefix=

#
# Help screen
#
help() {
  cat << OEF
Script for the installation step of GCC for the Vhex kernel.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
  --cache               Keep the build and sources directory
  --verbose             Display extra information during the installation step
  --prefix=<PREFIX>     Installation prefix
OEF
  exit 0
}



#
# Parse arguments
#

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



#
# Installation step
#

TAG='<sh-elf-vhex-gcc>'
PREFIX="$prefix"

# Check that the configuration step has been effectuated

if [[ ! -d ../../build/gcc/build ]]; then
  echo "error: Are you sure to have configured GCC ? it seems that" >&2
  echo "  the build directory is missing..." >&2
  exit 1
fi
cd ../../build/gcc

# Symbolic link executables to $PREFIX/bin

echo "$TAG Symlinking binaries..."
mkdir -p $PREFIX/bin
for x in bin/*; do
  ln -sf "$(pwd)/$x" "$PREFIX/$x"
done

# Cleanup build files

if [[ "$cache" == 'false' ]]; then
  echo "$TAG Cleaning up build files..."
  rm -rf gcc/
  rm -rf build/
fi
