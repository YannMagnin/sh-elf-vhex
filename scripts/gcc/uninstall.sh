#! /usr/bin/env bash

verbose=false
prefix=


#
# Help screen
#
help()
{
  cat << OEF
Script for the uninstallation of the Vhex kernel's GCC.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
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
  --prefix=*)           prefix=${arg#*=};;
  *)
    echo "error: unreconized argument '$arg', giving up." >&2
    exit 1
esac; done


#
# Unistall step
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

# Remove symlinks

echo "$TAG Removing symlinks to binaries..."

for x in bin/*; do
  rm "$PREFIX/$x"
done

# Remove local files

echo "$TAG Removing installed files..."
rm -rf ../gcc
exit 0
