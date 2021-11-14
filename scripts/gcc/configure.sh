#! /usr/bin/env bash

verbose=false
no_cache=false
version='?'
prefix=


#
# Help screen
#
help()
{
  cat << OEF
Configuration file for the configuration step of the GCC build for the Vhex
kernel project.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
  --no-cache            Do not keep the archive of binutils
  --verbose             Display extra information during the configuration step
  --prefix=<PREFIX>     Installation prefix
  --version=<VERSION>   Select the GCC version. If the '?' argument is
                        passed then all binutils version with Vhex patch
                        availables will be printed
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
  --no-cache)           no_cache=true;;
  --prefix=*)           prefix=${arg#*=};;
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
# @note
#  This part is forked from the sh-elf-binutils repository created by
#  Lephenixnoir.
#

TAG='<sh-elf-vhex-gcc>'
VERSION="$version"
PREFIX="$prefix"
URL="https://ftp.gnu.org/gnu/gcc/gcc-$VERSION/gcc-$VERSION.tar.xz"
ARCHIVE="../../cache/$(basename $URL)"

# Avoid rebuilds of the same version

existing_gcc="$PREFIX/bin/sh-elf-vhex-gcc"

if [[ -f "$existing_gcc" ]]; then
  existing_version=$($existing_gcc --version | head -n 1 | grep -Eo '[0-9.]+$')
  if [[ $existing_version == $VERSION ]]; then
    echo "$TAG Version $VERSION already installed, skipping rebuild"
    if [[ -e build ]]; then
      rm -rf build
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

# Rename the directory to avoid path deduction during configuration part in
# build.sh

[[ -d ./gcc ]] && rm -rf ./gcc
mv ./gcc-$VERSION/ ./gcc

# Symlink as, ld, ar and ranlib, which gcc will not find by itself (we renamed
# them from sh3eb-elf-* to sh-elf-* with --program-prefix).
mkdir -p sh-elf-vhex/bin
ln -sf $PREFIX/bin/sh-elf-vhex-as sh-elf-vhex/bin/as
ln -sf $PREFIX/bin/sh-elf-vhex-ld sh-elf-vhex/bin/ld
ln -sf $PREFIX/bin/sh-elf-vhex-ar sh-elf-vhex/bin/ar
ln -sf $PREFIX/bin/sh-elf-vhex-ranlib sh-elf-vhex/bin/ranlib

# patch OpenLibM building error (find for sh-elf-vhex-ar)
ln -sf $PREFIX/bin/sh-elf-vhex-ar sh-elf-vhex/bin/sh-elf-vhex-ar

if [[ "$no_cache" == 'true' ]]; then
   echo "$TAG Removing $ARCHIVE..."
   rm -f $ARCHIVE
fi
exit 0
