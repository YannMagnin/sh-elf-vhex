#! /usr/bin/env bash

#---
# Help screen
#---

function help() {
  cat << EOF
Script for the configuration step of Vhex's binutils.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
  --cache               Keep the archive of GCC
  --noconfirm           Skip user interaction
EOF
  exit 0
}

#---
# Parse arguments
#---

cached='true'
noconfirm='false'
prefix_sysroot=
version=
verbose=
for arg
  do case "$arg" in
    --help | -h)        help;;
    --verbose | -v)     verbose='true';;
    --no-cache)         cached='true';;
    --prefix-sysroot=*) prefix_sysroot=${arg#*=};;
    --version=*)        version=${arg#*=};;
    --noconfirm)        noconfirm='true';;
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

echo "$TAG Target gcc version -> $version"
echo "$TAG Sysroot found -> $prefix_sysroot"

#---
# Avoid rebuilding of the same version
#---

gcc_bin="$prefix_sysroot/bin/sh-elf-vhex-gcc"

if [[ -f "$gcc_bin" ]]
then
  gcc_version=$($gcc_bin --version | head -n 1 | grep -Eo '[0-9.]+$')
  if [[ "$gcc_version" == "$version" ]]
  then
    echo "$TAG Version $version already installed, skipping rebuilding"
    mkdir -p ../../_build/gcc/
    touch ../../_build/gcc/.fini
    exit 0
  fi
  [[ -d ../../_build/gcc/build ]] && rm -rf ../../_build/gcc/build
  [[ -f ../../_build/gcc/.fini ]] && rm -f  ../../_build/gcc/.fini
fi

#---
# Download archive
#---

utils_archive_download \
  "https://ftp.gnu.org/gnu/gcc/gcc-$version/gcc-$version.tar.xz" \
  ../../_build/gcc \
  "$cached"

#---
# Patch sources
#---

cd ../../_build/gcc || exit 1

echo "$TAG Apply Vhex patches..."
cp -r "../../patches/gcc/$version"/* ./archive/

# Store the sysroot prefix to avoid different CLI between binutils and gcc

echo "$prefix_sysroot" > ./sysroot_info.txt

# Create build folder

[[ -d "./build" ]] && rm -rf build
mkdir ./build

#---
# Install dependencies
#---

echo "$TAG install dependencies..."

cd ./archive || exit 1
if ! utils_warn_callcmd ./contrib/download_prerequisites
then
  echo 'The installation of GCC'\''s prerequisites has failed'
  if [[ "$noconfirm" == 'false' ]]
  then
    echo -en 'Do you want to continue the installation ? [yN]: '
    read -r valid < /dev/tty
    if [[ "$valid" != 'y' ]]; then
      echo 'Operation aborted o(x_x)o'
      exit 1
    fi
  fi
fi
