#! /usr/bin/env bash

verbose=false
prefix=

#---
# Help screen
#---
help()
{
  cat << OEF
Script for the uninstallation of the Vhex kernel's binutils.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
  --verbose             Display extra information during the uninstallation
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
  --prefix=*)           prefix=${arg#*=};;
  *)
    echo "error: unreconized argument '$arg', giving up." >&2
    exit 1
esac; done


#---
# Unistall step
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




#---
# Remove symlinks
#---

cd "$SYSROOT/bin"

echo "$TAG Removing symlinks to binaries..."
for x in *; do
  unlink "$PREFIX/$x"
done




#---
# Remove sysroot
#---

echo "$TAG Removing installed files..."
rm -rf "$SYSROOT"
