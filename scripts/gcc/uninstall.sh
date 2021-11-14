#! /usr/bin/env bash

verbose=false
prefix=


#
# Help screen
#
help()
{
  cat << OEF
Installation helper script for the configuration step of the binutils build for
the Vhex kernel project.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
  --verbose             Display extra information during the installation step
  --prefix=<PREFIX>     Installation prefix
OEF
  exit 0
}



#
# Parse argument
#

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

# Remove symlinks
echo "$TAG Removing symlinks to binaries..."
for x in bin/*; do
  rm "$PREFIX/$x"
done

# Remove local files
echo "$TAG Removing installed files..."
rm -rf ../../build/gcc
