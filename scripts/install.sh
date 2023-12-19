#! /usr/bin/env bash

#---
# Help screen
#---

function help() {
  cat << EOF
Script for the installation step of binutils/GCC tools for the Vhex project.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
  -v, --verbose         Display extra information during operation
      --prefix-install  Installation (bin) prefix
      --prefix-sysroot  Sysroot (lib, header, ...) prefix
      --prefix-clone    Clone prefix
      --overwrite       Remove the cloned version if exists and install
      --cache           Keep the build and the sources directory

Notes:
    This project will automatically install the vxLibc. You can use the
  VERBOSE env var to enable the verbose mode without explicit use of the
  '--verbose' option.
EOF
  exit 0
}

#---
# Parse arguments
#---

cache='false'
verbose='false'
overwrite='false'
prefix_install=~/.local/bin
prefix_sysroot=~/.local/share/sh-elf-vhex/_sysroot
prefix_clone=~/.local/share/sh-elf-vhex

for arg; do
  case "$arg" in
    --help | -h)        help;;
    --verbose | -v)     verbose=true;;
    --cache)            cache=true;;
    --prefix-sysroot=*) prefix_sysroot=${arg#*=};;
    --prefix-install=*) prefix_install=${arg#*=};;
    --prefix-clone=*)   prefix_clone=${arg#*=};;
    --overwrite)        overwrite='true';;
    *)
      echo "error: unrecognized argument '$arg', giving up." >&2
      exit 1
  esac
done

#---
# Handle bootstraping
#---

_src=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
cd "$_src" || exit 1

has_been_cloned='false'
if [[ "$prefix_clone/scripts" != "$_src" ]]
then
  if [ -x "$prefix_sysroot/bin/sh-elf-vhex-gcc" ]
  then
    echo -e \
      'It seems that the project is already installed :pouce:\n' \
      '\rIf you really want to reinstall this project use the ' \
      '"--overwrite" option.'
    exit 1
  fi
  if [[ ! -d "$prefix_clone" || "$overwrite" == 'true' ]]
  then
    [[ -d "$prefix_clone" ]] && rm -rf "$prefix_clone"
    echo '<sh-elf-vhex> self-clone repository...'
    {
      git \
        clone \
        --depth=1 \
        https://github.com/YannMagnin/sh-elf-vhex.git \
        "$prefix_clone"
    } || {
      exit 1
    }
    has_been_cloned='true'
  fi
fi

cd "$prefix_clone/scripts" || exit 1
source ./_utils.sh

#---
# Preliminary checks
#---

version_gcc=$(utils_find_last_version ../patches/gcc)
version_binutils=$(utils_find_last_version ../patches/binutils)

echo 'The script will install the sh-elf-vhex compiler with:'
echo " - GCC version:           $version_gcc"
echo " - Binutils version:      $version_binutils"
echo " - Clone directory:       $prefix_clone"
echo " - Compliler install at:  $prefix_install"
if [[ "$has_been_cloned" == 'true' ]]; then
  echo 'Note that the cloned repository will be removed if aborted'
fi
read -p 'Process ? [yN]: ' -r valid < /dev/tty

if [[ "$valid" != 'y' ]]; then
  if [[ "$has_been_cloned" == 'true' ]]; then
    echo 'Removing the cloned repository...'
    rm -rf "$prefix_clone"
  fi
  echo 'Operation aborted o(x_x)o'
  exit 1
fi

[[ "$verbose" == 'true' ]] && export VERBOSE=1

#---
# Handle GGC/Binutils build
#---

{
  ./binutils/configure.sh     \
      --prefix-sysroot="$prefix_sysroot"    \
      --version="$version_binutils"         \
  && ./binutils/build.sh      \
  && ./gcc/configure.sh       \
      --prefix-sysroot="$prefix_sysroot"    \
      --version="$version_gcc"              \
  && ./gcc/build.sh
} || {
    echo 'Error during installing operations' >&2
    exit 1
}

#---
# Handle manual installation to the install path
#---

echo "$TAG Symlinking binaries..."

mkdir -p "$prefix_install"
for x in "$prefix_sysroot/bin"/*; do
  utils_callcmd ln -sf "$x" "$prefix_install/$(basename "$x")"
done

#---
# Cleaning and exit
#---

if [[ "$cache" == 'false' ]]
then
  echo "$TAG Cleaning up built files..."
  rm -rf ../../build
fi

echo 'Successfully installed sh-elf-vhex !'
echo "Do not forget to export the binary path '$prefix_install'"
