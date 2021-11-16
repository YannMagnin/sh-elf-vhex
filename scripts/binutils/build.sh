#! /usr/bin/env bash

verbose=false

#
# Help screen
#
help() {
  cat << OEF
Script for the building step of binutils for the Vhex kernel.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
  --verbose             Display extra information during the building step
OEF
  exit 0
}



#
# Parse arguments
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

# Check that the configuration step has been effectuated

if [[ ! -d ../../build/binutils/build ]]; then
  echo "error: Are you sure to have configured binutils ? it seems that" >&2
  echo "  the build directory is missing..." >&2
  exit 1
fi
cd ../../build/binutils/build


# Import some helpers

source ../../../scripts/utils.sh


# Build part

echo "$TAG Compiling binutils (usually 5-10 minutes)..."

$quiet $make_cmd -j"$cores"

echo "$TAG Installing to local folder..."

$quiet $make_cmd install-strip
exit 0
