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
  --cache               Keep the archive of binutils
EOF
  exit 0
}

#---
# Parse arguments
#---

cache=false
for arg;
  do case "$arg" in
    --help | -h)    help;;
    --cache)        cache=true;;
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

VERSION=$(utils_get_env 'VHEX_VERSION_BINUTILS' 'binutils')
SYSROOT=$(utils_get_env 'VHEX_PREFIX_SYSROOT' 'sysroot')
URL="https://ftp.gnu.org/gnu/binutils/binutils-$VERSION.tar.xz"
ARCHIVE="/tmp/sh-elf-vhex/$(basename "$URL")"
TAG='<sh-elf-vhex-binutils>'

echo "$TAG Target binutils version -> $VERSION"
echo "$TAG Sysroot found -> $SYSROOT"

#---
# Avoid rebuilds of the same version
#---

as_bin="$SYSROOT/bin/sh-elf-vhex-as"

if [[ -f "$as_bin" ]]
then
  as_version=$($as_bin --version | head -n 1 | grep -Eo '[0-9.]+$')
  if [[ "$as_version" == "$VERSION" ]]
  then
    echo "$TAG Version $VERSION already installed, skipping rebuild" >&2
    mkdir -p ../../build/binutils/
    touch ../../build/binutils/.fini
    exit 0
  fi
  [[ -d ../../build/binutils/build ]] && rm -rf ../../build/binutils/build
  [[ -f ../../build/binutils/.fini ]] && rm -f  ../../build/binutils/.fini
fi

#---
# Check dependencies for binutils and GCC and offer to install them
#---

if command -v pkg >/dev/null 2>&1
then
  deps='cmake libmpfr libmpc libgmp libpng flex clang git texinfo'
  deps="$deps libisl bison xz-utils"
  pm='pkg'
  pm_has='dpkg -s'
  pm_install='pkg install'
elif command -v apt >/dev/null 2>&1
then
  deps='cmake libmpfr-dev libmpc-dev libgmp-dev libpng-dev libppl-dev'
  deps="$deps flex g++ git texinfo xz-utils"
  pm='apt'
  pm_has='dpkg -s'
  pm_install='sudo apt install'
elif command -v dnf >/dev/null 2>&1
then
  deps='cmake mpfr-devel libmpc-devel gmp-devel libpng-devel ppl-devel'
  deps="$deps flex gcc git texinfo xz"
  pm='dnf'
  pm_has="echo '$(rpm -qa)' | grep -i "
  pm_install='sudo dnf install'
  fix='-'
elif command -v pacman >/dev/null 2>&1
then
  deps='cmake mpfr libmpc gmp libpng ppl flex gcc git texinfo xz'
  pm='pacman'
  pm_has="pacman -Qi"
  pm_install="sudo pacman -S"
else
  trust_deps=1
fi

missing=''
if [[ -z "$trust_deps" ]]; then
  for d in $deps; do
    if ! bash -c "$pm_has $d$fix" >/dev/null 2>&1; then
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
  read -r do_install
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
      "$TAG error: no curl or wget; install one or download "
      'archive yourself' >&2
    exit 1
  fi
fi

#---
# Extract archive (OpenBDS-compliant version)
#---

echo "$TAG Extracting $ARCHIVE..."

mkdir -p ../../build/binutils
cd ../../build/binutils/ || exit 1

unxz -c < "$ARCHIVE" | tar -xf -

# Touch intl/plural.c to avoid regenerating it from intl/plural.y with
# recent versions of bison, which is subject to the following known bug.
# * https://sourceware.org/bugzilla/show_bug.cgi?id=22941
# * https://gcc.gnu.org/bugzilla/show_bug.cgi?id=92008
touch "binutils-$VERSION/intl/plural.c"

# Apply binutils patchs for Vhex

echo "$TAG Apply Vhex patchs..."
cp -r "$_src/../../patches/binutils/$VERSION"/* ./binutils-"$VERSION"/

# Create build folder

[[ -d "build" ]] && rm -rf build
mkdir build && cd build || exit 1

#---
# Real configuration step
#---

echo "$TAG Configuring binutils..."

$quiet "../binutils-$VERSION/configure" \
  --prefix="$SYSROOT"                   \
  --target='sh-elf-vhex'                \
  --program-prefix='sh-elf-vhex-'       \
  --with-multilib-list='m3,m4-nofpu'    \
  --enable-lto                          \
  --enable-shared                       \
  --disable-nls

#---
# Cache management
#---

if [[ "$cache" == 'false' ]]
then
  echo "$TAG Removing $ARCHIVE..."
  rm -f "$ARCHIVE"
fi

exit 0
