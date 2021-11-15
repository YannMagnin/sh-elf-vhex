#! /usr/bin/env bash

verbose=false

#
# Help screen
#
help()
{
  cat << OEF
Building helper script for the configuration step of the binutils build for the
Vhex kernel project.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
  --verbose             Display extra information during the building step
OEF
  exit 0
}



#
# Parse argument
#

for arg; do case "$arg" in
  --help | -h)          help;;
  --verbose)            verbose=true;;
  *)
    echo "error: unreconized argument '$arg', giving up." >&2
    exit 1
esac; done



#
# Building step
#

TAG='<sh-elf-vhex-binutils>'


# Avoid rebuilds of the same version
[[ ! -d ../../build/binutils/build ]] && exit 0
cd ../../build/binutils/build


# import some utility
source ../../../scripts/utils.sh


# build part
echo "$TAG Compiling binutils (usually 5-10 minutes)..."

$quiet $make_cmd -j"$cores"

echo "$TAG Installing to local folder..."

$quiet $make_cmd install-strip
