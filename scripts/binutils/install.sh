#! /usr/bin/env bash

verbose=false
cache=false
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
  --cache               Keep the build and sources directory
  --verbose             Display extra information during the installation step
  --prefix=<PREFIX>     Installation prefix
OEF
  exit 0
}



#
# Parse argument
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
# @note
#  This part is forked from the sh-elf-binutils repository created by
#  Lephenixnoir.
#

TAG='<sh-elf-vhex-binutils>'
PREFIX="$prefix"

# Avoid rebuilds of the same version

[[ ! -d ../../build/binutils/build ]] && exit 0
cd ../../build/binutils

# Symbolic link executables to $PREFIX/bin

echo "$TAG Symlinking binaries..."
mkdir -p $PREFIX/bin
for x in bin/*; do
  ln -sf "$(pwd)/$x" "$PREFIX/$x"
done

# Cleanup build files

if [[ "$cache" == 'false' ]]; then
  echo "$TAG Cleaning up build files..."
  rm -rf binutils-*/
  rm -rf build/
fi
