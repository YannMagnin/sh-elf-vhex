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
Configuration file for the configuration step of the binutils build for the
Vhex kernel project.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
  --no-cache            Do not keep the archive of binutils
  --verbose             Display extra information during the configuration step
  --prefix=<PREFIX>     Installation prefix
  --version=<VERSION>   Select the binutils version. If the '?' argument is
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
list_version=$(basename $(ls -d ../../patchs/binutils/*))
if [[ "$version" == '?' ]];  then
  echo "$list_version"
  exit 0
fi
if [[ ! $list_version =~ (^|[[:space:]])$version($|[[:space:]]) ]]; then
  echo "binutils version '$version' is not supported by Vhex"
  echo 'abording...'
  exit 1
fi



#
# Configuration part
# @note
#  This part is forked from the sh-elf-binutils repository created by
#  Lephenixnoir.
#

TAG='<sh-elf-vhex-binutils>'
VERSION=$version
PREFIX="$prefix"
URL="https://ftp.gnu.org/gnu/binutils/binutils-$VERSION.tar.xz"
ARCHIVE="../../cache/$(basename $URL)"

# Avoid rebuilds of the same version

existing_as="$PREFIX/bin/sh-elf-vhex-as"

if [[ -f "$existing_as" ]]; then
  existing_version=$($existing_as --version | head -n 1 | grep -Eo '[0-9.]+$')
  if [[ $existing_version == $VERSION ]]; then
    echo "$TAG Version $VERSION already installed, skipping rebuild"
    if [[ -e build ]]; then
      rm -rf build
    fi
    exit 0
  fi
fi

# Check dependencies for binutils and GCC
if command -v pkg >/dev/null 2>&1; then
  deps="libmpfr libmpc libgmp libpng flex clang git texinfo libisl bison xz-utils"
  pm=pkg
  pm_has="dpkg -s"
  pm_install="pkg install"
elif command -v apt >/dev/null 2>&1; then
  deps="libmpfr-dev libmpc-dev libgmp-dev libpng-dev libppl-dev flex g++ git texinfo xz-utils"
  pm=apt
  pm_has="dpkg -s"
  pm_install="sudo apt install"
elif command -v pacman >/dev/null 2>&1; then
  deps="mpfr libmpc gmp libpng ppl flex gcc git texinfo xz"
  pm=pacman
  pm_has="pacman -Qi"
  pm_install="sudo pacman -S"
else
  trust_deps=1
fi

missing=""
if [[ -z "$trust_deps" ]]; then
  for d in $deps; do
    if ! $pm_has $d >/dev/null 2>&1; then
      missing="$missing $d"
    fi
  done
fi

# Offer to install dependencies

if [[ ! -z "$missing" ]]; then
  echo "$TAG Based on $pm, some dependencies are missing: $missing"
  echo -n "$TAG Do you want to run '$pm_install $missing' to install them (Y/n)? "

  read do_install
  if [[ "$do_install" == "y" || "$do_install" == "Y" || "$do_install" == "" ]]; then
    $pm_install $missing
  else
    echo "$TAG Skipping dependencies, hoping it will build anyway."
  fi
fi

# Download archive

if [[ -f "$ARCHIVE" ]]; then
  echo "$TAG Found $ARCHIVE, skipping download"
else
  mkdir -p $(dirname "$ARCHIVE")
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

# Extract archive (OpenBDS-compliant version)

echo "$TAG Extracting $ARCHIVE..."

mkdir -p ../../build/binutils/
cd ../../build/binutils

unxz -c < $ARCHIVE | tar -xf -


# Touch intl/plural.c to avoid regenerating it from intl/plural.y with recent
# versions of bison, which is subject to the following known bug.
# * https://sourceware.org/bugzilla/show_bug.cgi?id=22941
# * https://gcc.gnu.org/bugzilla/show_bug.cgi?id=92008
touch binutils-$VERSION/intl/plural.c

# Apply binutils patchs for Vhex

echo "$TAG Apply Vhex patchs..."
cp -r ../../patchs/binutils/$VERSION/* ./binutils-$VERSION/

# Create build folder

[[ -d "build" ]] && rm -rf build
mkdir build

# Configure. binutils does not support the uninstall target (wow) so we just
# install in this directory and later symlink executables to $PREFIX/bin.

PREFIX="$(pwd)"
cd build

echo "$TAG Configuring binutils..."

if command -v termux-setup-storage >/dev/null 2>&1; then
  # Since the __ANDROID_API__ flag is hardcoded as 24 in clang, and <stdio.h>
  # doesn't prototype some functions when this flag is too low, fixes it's
  # version by checking system's properties so as to prevent from missing prototypes
  # of existing functions such as fgets_unlocked (only if API >= 28)
  # See the following issues :
  # * https://github.com/termux/termux-packages/issues/6176
  # * https://github.com/termux/termux-packages/issues/2469

  export CFLAGS="-D__ANDROID_API__=$(getprop ro.build.version.sdk) -g -O2" \
  CXXFLAGS="-D__ANDROID_API__=$(getprop ro.build.version.sdk) -g -O2"
fi

# Real configuration step
if [[ "$verbose" == "true" ]]; then
  ../binutils-$VERSION/configure --prefix="$PREFIX" --target=sh-elf-vhex \
       --with-multilib-list=m3,m4-nofpu --disable-nls --enable-lto
else
  source ../../../scripts/util.sh

  run_quietly giteapc-configure.log \
    ../binutils-$VERSION/configure --prefix="$PREFIX" --target=sh-elf-vhex \
        --with-multilib-list=m3,m4-nofpu --disable-nls --enable-lto
fi
cd ..

# cache management
if [[ "$no_cache" == 'true' ]]; then
   echo "$TAG Removing $ARCHIVE..."
   rm -f $ARCHIVE
fi
exit 0
