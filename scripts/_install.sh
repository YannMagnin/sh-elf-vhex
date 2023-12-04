#! /usr/bin/env bash

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

cache=false
verbose=false
prefix_install=
prefix_sysroot=

for arg; do
  case "$arg" in
    --help | -h)        help;;
    --verbose | -v)     verbose=true;;
    --cache)            cache=true;;
    --prefix-sysroot=*) prefix_sysroot=${arg#*=};;
    --prefix-install=*) prefix_install=${arg#*=};;
    *)
      echo "error: unrecognized argument '$arg', giving up." >&2
      exit 1
  esac
done

#---
# Installation step
#---

_src=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$_src" || exit 1
source ./_utils.sh

if [[ ! -f "$prefix_sysroot/bin/sh-elf-vhex-gcc" ]]
then
  echo "error: Are you sure to have built sh-elf-vhex ? it seems that" >&2
  echo "  the 'as' tool is missing..." >&2
  exit 1
fi

if [[ "$cache" == 'false' ]]
then
  echo "$TAG Cleaning up build files..."
  rm -rf ../../build
fi

[[ "$verbose" == 'true' ]] && export VERBOSE=1

#---
# Symbolic link executables to $PREFIX
#---

echo "$TAG Symlinking binaries..."

mkdir -p "$prefix_install"
for x in "$prefix_sysroot/bin"/*; do
  utils_callcmd ln -sf "$x" "$prefix_install/$(basename "$x")"
done
