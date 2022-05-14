#! /usr/bin/env bash

verbose=false
cache=false
prefix=

#
# Help screen
#
help() {
  cat << OEF
Script for the installation step of binutils for the Vhex kernel.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
  --cache               Keep the build and the sources directory
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

TAG='<sh-elf-vhex-binutils>'
PREFIX="$prefix"

# Check that all tools has been generated

existing_as="../../build/binutils/bin/sh-elf-vhex-as"

if [[ ! -f "$existing_as" ]]; then
  echo "error: Are you sure to have built binutils ? it seems that" >&2
  echo "  the 'as' tool is missing..." >&2
  exit 1
fi
cd ../../build/binutils/bin

# Symbolic link executables to $PREFIX/bin

echo "$TAG Symlinking binaries..."
mkdir -p $PREFIX
for x in *; do
  ln -sf "$(pwd)/$x" "$PREFIX/$x"
done

# Cleanup build files

if [[ "$cache" == 'false' ]]; then
  echo "$TAG Cleaning up build files..."
  rm -rf binutils-*/
  rm -rf build/
fi
