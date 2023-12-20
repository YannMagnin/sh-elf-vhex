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
  -v, --verbose         Display extra information during operation
      --no-cache        Do not keep the archive of binutils
      --prefix-sysroot  Sysroot (lib, header, ...) prefix
      --version         Binutils version
EOF
  exit 0
}

#---
# Parse arguments
#---

cached='true'
prefix_sysroot=
version=
for arg;
  do case "$arg" in
    --help | -h)        help;;
    --verbose | -v)     verbose='true';;
    --prefix-sysroot=*) prefix_sysroot=${arg#*=};;
    --version=*)        version=${arg#*=};;
    --no-cache)         cached='false';;
    *)
      echo "error: unrecognized argument '$arg', giving up" >&2
      exit 1
  esac
done

#---
# Configuration part
#---

_src=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$_src" || exit 1
source ../_utils.sh

if [[ ! -d "../../patches/binutils/$version" ]]
then
  echo "Binutils version '$version' not supported, abort" >&2
  exit 1
fi

[[ "$verbose" == 'true' ]] && export VERBOSE=1

echo "$TAG Target binutils version -> $version"
echo "$TAG Sysroot found -> $prefix_sysroot"

#---
# Avoid rebuilds of the same version
#---

as_bin="$prefix_sysroot/bin/sh-elf-vhex-as"

if test -f "$as_bin"
then
  as_version=$($as_bin --version | head -n 1 | grep -Eo '[0-9.]+$')
  if [[ "$as_version" == "$version" ]]
  then
    echo "$TAG Version '$version' already installed, skipping rebuilding" >&2
    mkdir -p ../../_build/binutils/
    touch ../../_build/binutils/.fini
    exit 0
  fi
  [[ -d ../../_build/binutils/build ]] && rm -rf ../../_build/binutils/build
  [[ -f ../../_build/binutils/.fini ]] && rm -f  ../../_build/binutils/.fini
fi

#---
# Check dependencies for binutils and GCC and offer to install them
#---

if [[ "$(uname -s)" == 'Darwin' ]]
then
  deps='cmake mpfr libmpc gmp libpng ppl flex gcc git texinfo xz gcc'
  pm='brew'
  pm_has='brew list | grep -i'
  pm_install='brew install'
  fix='^'
elif command -v pkg >/dev/null 2>&1
then
  deps='cmake libmpfr libmpc libgmp libpng flex clang git texinfo'
  deps="$deps libisl bison xz-utils gcc"
  pm='pkg'
  pm_has='dpkg -s'
  pm_install='ASSUME_ALWAYS_YES=yes pkg install'
elif command -v apt >/dev/null 2>&1
then
  deps='cmake libmpfr-dev libmpc-dev libgmp-dev libpng-dev libppl-dev'
  deps="$deps flex g++ git texinfo xz-utils gcc"
  pm='apt'
  pm_has='dpkg -s'
  pm_install='sudo apt install -y'
elif command -v dnf >/dev/null 2>&1
then
  deps='cmake mpfr-devel libmpc-devel gmp-devel libpng-devel ppl-devel'
  deps="$deps flex gcc git texinfo xz gcc-c++"
  pm='dnf'
  pm_has='dnf list installed | grep -i'
  pm_install='sudo dnf install -y'
  fix='^'
elif command -v pacman >/dev/null 2>&1
then
  deps='cmake mpfr libmpc gmp libpng ppl flex gcc git texinfo xz gcc'
  pm='pacman'
  pm_has='pacman -Qi'
  pm_install='sudo pacman -S --noconfirm'
else
  trust_deps=1
fi

missing=''
if [[ -z "$trust_deps" ]]; then
  for d in $deps; do
    if ! bash -c "$pm_has $fix$d" >/dev/null 2>&1; then
      missing="$missing $d"
    fi
  done
fi

if [[ -n "$missing" ]]
then
  echo -en \
    "$TAG Based on $pm, some dependencies are missing: $missing\n" \
    "$TAG Do you want to run '$pm_install $missing' to install "   \
    'them [nY]? '
  read -r do_install < /dev/tty
  if [[ "$do_install" != 'n' ]]
  then
    bash -c "$pm_install $missing"
  else
    echo "$TAG Skipping dependencies, hoping it will build anyway."
  fi
fi

#---
# Download archive
#---

utils_archive_download \
  "https://ftp.gnu.org/gnu/binutils/binutils-$version.tar.xz" \
  ../../_build/binutils \
  "$cached"

#---
# Patch sources
#---

cd ../../_build/binutils || exit 1

# Touch intl/plural.c to avoid regenerating it from intl/plural.y with
# recent versions of bison, which is subject to the following known bug.
# * https://sourceware.org/bugzilla/show_bug.cgi?id=22941
# * https://gcc.gnu.org/bugzilla/show_bug.cgi?id=92008
touch ./archive/intl/plural.c

# Apply binutils patches for Vhex

echo "$TAG Apply Vhex patches..."
cp -r "$_src/../../patches/binutils/$version"/* ./archive/

# Create build folder

[[ -d "build" ]] && rm -rf build
mkdir build && cd build || exit 1

#---
# Real configuration step
#---

echo "$TAG Configuring binutils..."

utils_callcmd \
  ../archive/configure                  \
  --prefix="$prefix_sysroot"            \
  --target='sh-elf-vhex'                \
  --program-prefix='sh-elf-vhex-'       \
  --with-multilib-list='m3,m4-nofpu'    \
  --enable-lto                          \
  --enable-shared                       \
  --disable-nls
