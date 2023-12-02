#! /usr/bin/env bash

#---
# Help screen
#---

function help() {
  cat << EOF
Script for the configuration step of Vhex kernel's binutils.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
  --cache               Keep the archive of GCC
EOF
  exit 0
}

#---
# Parse arguments
#---

cache=false
for arg
  do case "$arg" in
    --help | -h)    help;;
    --cache)        cache=true;;
    *)
      echo "error: unreconized argument '$arg', giving up." >&2
      exit 1
  esac
done

#---
# Configuration part
#---

_src=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$_src" || exit 1
source ../_utils.sh

VERSION=$(utils_get_env 'VHEX_VERSION_GCC' 'binutils')
SYSROOT=$(utils_get_env 'VHEX_PREFIX_SYSROOT' 'sysroot')
URL="https://ftp.gnu.org/gnu/gcc/gcc-$VERSION/gcc-$VERSION.tar.xz"
ARCHIVE="/tmp/sh-elf-vhex/$(basename "$URL")"
TAG='<sh-elf-vhex-gcc>'

echo "$TAG Target gcc version -> $VERSION"
echo "$TAG Sysroot found -> $SYSROOT"

#---
# Avoid rebuilds of the same version
#---

gcc_bin="$SYSROOT/bin/sh-elf-vhex-gcc"

if [[ -f "$gcc_bin" ]]
then
  gcc_version=$($gcc_bin --version | head -n 1 | grep -Eo '[0-9.]+$')
  if [[ "$gcc_version" == "$VERSION" ]]
  then
    echo "$TAG Version $VERSION already installed, skipping rebuild"
    mkdir -p ../../build/gcc/
    touch ../../build/gcc/.fini
    exit 0
  fi
  [[ -d ../../build/gcc/build ]] && rm -rf ../../build/gcc/build
  [[ -f ../../build/gcc/.fini ]] && rm -f  ../../build/gcc/.fini
fi

#---
# Download archive
#---

[[ "$cache" == 'false' && -f "$ARCHIVE" ]] && rm -f "$ARCHIVE"

mkdir -p "$(dirname "$ARCHIVE")"
if [[ -f "$ARCHIVE" ]]
then
  echo "$TAG Found $ARCHIVE, skipping download"
else
  echo "$TAG Downloading $URL..."
  if command -v curl >/dev/null 2>&1
  then
    curl "$URL" -o "$ARCHIVE"
  elif command -v wget >/dev/null 2>&1
  then
    wget -q --show-progress "$URL" -O "$ARCHIVE"
  else
    echo \
      "$TAG error: no curl or wget; install one or download archive " \
      ' yourself' >&2
    exit 1
  fi
fi

#---
# Extract archive (openBSD-compliant version)
#---

echo "$TAG Extracting $ARCHIVE..."

mkdir -p ../../build/gcc && cd ../../build/gcc/ || exit 1

unxz -c < "$ARCHIVE" | tar -xf -

#---
# Apply GCC patchs for Vhex
#---

echo "$TAG Apply Vhex patchs..."
cp -r "../../patches/gcc/$VERSION"/* "./gcc-$VERSION"/

# Rename the extracted directory to avoid path deduction during building
# step (so the build script will use explicitly ...build/gcc/... path)

[[ -d ./gcc ]] && rm -rf ./gcc
mv "./gcc-$VERSION/" ./gcc

#---
# Install dependencies
#---

echo "$TAG install dependencies..."

cd gcc || exit 1
$quiet ./contrib/download_prerequisites
cd .. || exit 1

mkdir -p build

#---
# Cache management
#---

if [[ "$cache" == 'false' ]]
then
   echo "$TAG Removing $ARCHIVE..."
   rm -f "$ARCHIVE"
fi
