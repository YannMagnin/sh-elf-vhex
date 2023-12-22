#! /usr/bin/env bash

#---
# Help screen
#---

function help() {
  cat << EOF
Script for the building step of binutils for the Vhex project.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
EOF
  exit 0
}

#---
# Parse arguments
#---

for arg;
  do case "$arg" in
    --help | -h)    help;;
    *)
      echo "error: unrecognized argument '$arg', giving up." >&2
      exit 1
  esac
done

#---
# Setup check
#---

_src=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$_src" || exit 1
source ../_utils.sh

# Avoid rebuilds and error

if [[ -f ../../_build/binutils/.fini  ]]
then
  echo "$TAG already built, skipping rebuild"
  exit 0
fi

if [[ ! -d ../../_build/binutils/build ]]
then
  echo "error: Are you sure to have configured binutils ? it seems that" >&2
  echo "  the build directory is missing..." >&2
  exit 1
fi

cd ../../_build/binutils/build || exit 1

#---
# Build part
#---

echo "$TAG Compiling binutils (usually 5-10 minutes)..."

utils_makecmd

echo "$TAG Installing binutils to sysroot..."

utils_makecmd install-strip

# Indicate that the construction is finished

rm -rf ../build
rm -rf ../archive
touch ../.fini
