#! /usr/bin/env bash

verbose=false
cache=true
version='?'

#---
# Help screen
#---
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



#---
# Parse arguments
#---

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

#---
# check version
#---

list_version=''
for tmp in $(ls -d ../../patchs/gcc/*); do
  list_version="$list_version $(basename $tmp)"
done
if [[ "$version" == '?' ]];  then
  echo "GCC available versions:"
  for ver in $list_version; do
    echo "  $ver"
  done
  exit 0
fi
if [[ ! $list_version =~ (^|[[:space:]])$version($|[[:space:]]) ]]; then
  echo "GCC version '$version' is not supported by Vhex"
  echo 'abording...'
  exit 1
fi

#---
# Import some helpers
# <> get_sysroot() -> workaround with the vxsdk to fetch the sysroot path
# <> run_quietly() -> do not display command logs and save them in log files
#---

source ../../scripts/utils.sh

#---
# Configuration part
#---

TAG='<sh-elf-vhex-gcc>'
VERSION="$version"
URL="https://ftp.gnu.org/gnu/gcc/gcc-$VERSION/gcc-$VERSION.tar.xz"
ARCHIVE="/tmp/sh-elf-vhex/$(basename $URL)"
SYSROOT="$(get_sysroot)"

#---
# Avoid rebuilds of the same version
#---

existing_gcc="$SYSROOT/bin/sh-elf-vhex-gcc"

if [[ -f "$existing_gcc" ]]; then
  existing_version=$($existing_gcc --version | head -n 1 | grep -Eo '[0-9.]+$')
  if [[ $existing_version == $VERSION ]]; then
    echo "$TAG Version $VERSION already installed, skipping rebuild"
    exit 0
  fi
  [[ -d ../../build/gcc/build ]] && rm -rf ../../build/gcc/build
  [[ -f ../../build/gcc/.fini ]] && rm -f  ../../build/gcc/.fini
fi

#---
# Download archive
#---

if [[ "$cache" == 'false' ]]; then
  if [[ -f "$ARCHIVE" ]]; then
    rm -f "$ARCHIVE"
  fi
fi
mkdir -p $(dirname "$ARCHIVE")
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

#---
# Extract archive (openBSD-compliant version)
#---

echo "$TAG Extracting $ARCHIVE..."

mkdir -p ../../build/gcc
cd ../../build/gcc/

unxz -c < $ARCHIVE | tar -xf -

#---
# Apply GCC patchs for Vhex
#---

echo "$TAG Apply Vhex patchs..."
cp -r ../../patchs/gcc/$VERSION/* ./gcc-$VERSION/

# Rename the extracted directory to avoid path deduction during building step
# (so the build script will use explicitly ...build/gcc/... path)

[[ -d ./gcc ]] && rm -rf ./gcc
mv ./gcc-$VERSION/ ./gcc

#---
# Install dependencies
#---

cd gcc
./contrib/download_prerequisites
cd ..

mkdir -p build

#---
# Cache management
#---

if [[ "$cache" == 'false' ]]; then
   echo "$TAG Removing $ARCHIVE..."
   rm -f "$ARCHIVE"
fi

exit 0
