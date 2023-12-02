#! /usr/bin/env bash

#---
# Help screen
#---

function help() {
  cat << EOF
Script for the building step of binutils for the Vhex kernel.

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
      echo "error: unreconized argument '$arg', giving up." >&2
      exit 1
  esac
done

#---
# Setup check
#---

_src=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$_src" || exit 1
source ../_utils.sh

TAG='<sh-elf-vhex-binutils>'

# Avoid rebuilds and error

if [[ -f ../../build/binutils/.fini  ]]
then
  echo "$TAG already build, skipping rebuild"
  exit 0
fi

if [[ ! -d ../../build/binutils/build ]]
then
  echo "error: Are you sure to have configured binutils ? it seems that" >&2
  echo "  the build directory is missing..." >&2
  exit 1
fi

cd ../../build/binutils/build || exit 1

#---
# Build part
#---

echo "$TAG Compiling binutils (usually 5-10 minutes)..."

$quiet $make_cmd -j"$cores"

echo "$TAG Installing binutils to sysroot..."

$quiet $make_cmd install-strip

# Indicate that the build is finished

touch ../.fini
exit 0
