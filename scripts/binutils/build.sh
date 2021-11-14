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

# Number of processor cores
[[ $(uname) == "OpenBSD" ]] && cores=$(sysctl -n hw.ncpu) || cores=$(nproc)

# selecte make utility
[[ $(command -v gmake >/dev/null 2>&1) ]] && make_cmd=gmake || make_cmd=make

echo "$TAG Compiling binutils (usually 5-10 minutes)..."

if [[ "$verbose" == 'false' ]]; then
  source ../../../scripts/util.sh
  run_quietly giteapc-build.log $make_cmd -j"$cores"
else
  $make_cmd -j"$cores"
fi
