#! /usr/bin/env bash

verbose=false
cache=false
prefix=

#---
# Help screen
#---

function help() {
  cat << EOF
Script for the installation step of binutils/GCC tools for the Vhex kernel.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
  --cache               Keep the build and the sources directory
EOF
  exit 0
}

#---
# Parse arguments
#---

for arg
  do case "$arg" in
    --help | -h)    help;;
    --cache)        cache=true;;
    *)
      echo "error: unreconized argument '$arg', giving up." >&2
      exit 1
  esac
done

#---
# Installation step
#---

_src=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$_src" || exit 1
source ./_utils.sh

TAG='<sh-elf-vhex>'
SYSROOT=$(utils_get_env 'VHEX_PREFIX_SYSROOT' 'sysroot')
INSTALL=$(utils_get_env 'VHEX_PREFIX_INSTALL' 'install')

# Check that all tools has been generated

if [[ ! -f "$SYSROOT/bin/sh-elf-vhex-gcc" ]]
then
  echo "error: Are you sure to have built sh-elf-vhex ? it seems that" >&2
  echo "  the 'as' tool is missing..." >&2
  exit 1
fi

# Cleanup build files

if [[ "$cache" == 'false' ]]
then
  echo "$TAG Cleaning up build files..."
  rm -rf ../../build
fi

#---
# Symbolic link executables to $PREFIX
#---

echo "$TAG Symlinking binaries..."

mkdir -p "$INSTALL"
for x in "$SYSROOT/bin"/*; do
  ln -s "$x" "$INSTALL/$x"
done
