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
prefix_sysroot=
version=
verbose=
for arg
  do case "$arg" in
    --help | -h)        help;;
    --verbose | -v)     verbose=true;;
    --cache)            cache=true;;
    --prefix-sysroot=*) prefix_sysroot=${arg#*=};;
    --version=*)        version=${arg#*=};;
    *)
      echo "error: unrecognized argument '$arg', giving up." >&2
      exit 1
  esac
done

#---
# Configuration part
#---

_src=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$_src" || exit 1
source ../_utils.sh

if [[ ! -d "../../patches/gcc/$version" ]]
then
  echo "Binutils version '$version' not supported, abort" >&2
  exit 1
fi

[[ "$verbose" == 'true' ]] && export VERBOSE=1

url="https://ftp.gnu.org/gnu/gcc/gcc-$version/gcc-$version.tar.xz"
archive="/tmp/sh-elf-vhex/$(basename "$url")"

echo "$TAG Target gcc version -> $version"
echo "$TAG Sysroot found -> $prefix_sysroot"

#---
# Avoid rebuilds of the same version
#---

gcc_bin="$prefix_sysroot/bin/sh-elf-vhex-gcc"

if [[ -f "$gcc_bin" ]]
then
  gcc_version=$($gcc_bin --version | head -n 1 | grep -Eo '[0-9.]+$')
  if [[ "$gcc_version" == "$version" ]]
  then
    echo "$TAG Version $version already installed, skipping rebuild"
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

mkdir -p "$(dirname "$archive")"
if [[ -f "$archive" ]]
then
  echo "$TAG Found $archive, skipping download"
else
  echo "$TAG Downloading $url..."
  if command -v curl >/dev/null 2>&1
  then
    curl "$url" -o "$archive"
  elif command -v wget >/dev/null 2>&1
  then
    wget -q --show-progress "$url" -O "$archive"
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

echo "$TAG Extracting $archive..."

mkdir -p ../../build/gcc && cd ../../build/gcc/ || exit 1

unxz -c < "$archive" | tar -xf -

#---
# Apply GCC patchs for Vhex
#---

echo "$TAG Apply Vhex patchs..."
cp -r "../../patches/gcc/$version"/* "./gcc-$version"/

# Rename the extracted directory to avoid path deduction during building
# step (so the build script will use explicitly ...build/gcc/... path)

[[ -d ./gcc ]] && rm -rf ./gcc
mv "./gcc-$version/" ./gcc

# also store the sysroot prefix to avoid different CLI between binutils and
# gcc

echo "$prefix_sysroot" > ./sysroot_info.txt

#---
# Install dependencies
#---

echo "$TAG install dependencies..."

cd gcc || exit 1
utils_callcmd ./contrib/download_prerequisites
cd .. || exit 1

mkdir -p build

#---
# Cache management
#---

if [[ "$cache" == 'false' ]]
then
   echo "$TAG Removing $archive..."
   rm -f "$archive"
fi
