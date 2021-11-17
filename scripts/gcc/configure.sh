#! /usr/bin/env bash

verbose=false
cache=false
version='?'

#
# Help screen
#
help() {
  cat << OEF
Script for the configuration step of Vhex kernel's binutils.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
  --cache               Keep the archive of GCC
  --verbose             Display extra information during the configuration step
  --version=<VERSION>   Select the GCC version. If '?' argument is passed,
                          then all GCC version with Vhex patchs available
                          will be displayed
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
  --cache)              cache=true;;
  --version=*)          version=${arg#*=};;
  *)
    echo "error: unreconized argument '$arg', giving up." >&2
    exit 1
esac; done


#
# Check parsing validity
#

# check version

list_version=$(basename $(ls -d ../../patchs/gcc/*))
if [[ "$version" == '?' ]];  then
  echo "$list_version"
  exit 0
fi
if [[ ! $list_version =~ (^|[[:space:]])$version($|[[:space:]]) ]]; then
  echo "GCC version '$version' is not supported by Vhex"
  echo 'abording...'
  exit 1
fi



#
# Configuration part
#

TAG='<sh-elf-vhex-gcc>'
VERSION="$version"
URL="https://ftp.gnu.org/gnu/gcc/gcc-$VERSION/gcc-$VERSION.tar.xz"
ARCHIVE="../../cache/$(basename $URL)"

# Avoid rebuilds of the same version

existing_gcc="../../build/gcc/bin/sh-elf-vhex-gcc"

if [[ -f "$existing_gcc" ]]; then
  existing_version=$($existing_gcc --version | head -n 1 | grep -Eo '[0-9.]+$')
  if [[ $existing_version == $VERSION ]]; then
    echo "$TAG Version $VERSION already installed, skipping rebuild"
    if [[ -e ../../build/gcc/build ]]; then
      rm -rf ../../build/gcc/build
    fi
    exit 0
  fi
fi

# Download archive

if [[ -f "$ARCHIVE" ]]; then
  echo "$TAG Found $ARCHIVE, skipping download"
else
  echo "$TAG Downloading $URL..."
  if command -v curl >/dev/null 2>&1; then
    curl $URL -o $ARCHIVE
  elif command -v wget >/dev/null 2>&1; then
    wget -q --show-progress $URL -O $ARCHIVE
  else
    echo "$TAG error: no curl or wget; install one or download archive yourself" >&2
    exit 1
  fi
fi

# Extract archive (openBSD-compliant version)

echo "$TAG Extracting $ARCHIVE..."

mkdir -p ../../build/gcc/
cd ../../build/gcc

unxz -c < $ARCHIVE | tar -xf -

# Apply GCC patchs for Vhex

echo "$TAG Apply Vhex patchs..."
cp -r ../../patchs/gcc/$VERSION/* ./gcc-$VERSION/

# Rename the extracted directory to avoid path deduction during building strep

[[ -d ./gcc ]] && rm -rf ./gcc
mv ./gcc-$VERSION/ ./gcc

# Install dependencies

cd gcc
./contrib/download_prerequisites
cd ..

# Symlink as, ld, ar and ranlib, which gcc will not find by itself (we renamed
# them from sh3eb-elf-* to sh-elf-* with --program-prefix).

mkdir -p sh-elf-vhex/bin
ln -sf $(pwd)/../binutils/bin/sh-elf-vhex-as sh-elf-vhex/bin/as
ln -sf $(pwd)/../binutils/bin/sh-elf-vhex-ld sh-elf-vhex/bin/ld
ln -sf $(pwd)/../binutils/bin/sh-elf-vhex-ar sh-elf-vhex/bin/ar
ln -sf $(pwd)/../binutils/bin/sh-elf-vhex-ranlib sh-elf-vhex/bin/ranlib

# Patch OpenLibM building error (which search for sh-elf-vhex-ar)
ln -sf $(pwd)/../binutils/bin/sh-elf-vhex-ar sh-elf-vhex/bin/sh-elf-vhex-ar

# Cache management

if [[ "$cache" == 'false' ]]; then
   echo "$TAG Removing $ARCHIVE..."
   rm -f $ARCHIVE
fi
exit 0
