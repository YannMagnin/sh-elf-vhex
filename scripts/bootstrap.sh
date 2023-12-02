#!/usr/bin/env bash

#---
# Help screen
#---

function help() {
  cat << OEF
Bootstrap script used to install or uninstall the sh-elf-vhex compiler.

Usage $0 [options...]

Options:
  -h, --help            Display this help
  -v, --verbose         Display extra information during operation
      --prefix-install  Installation prefix
      --prefix-sysroot  Sysroot prefix
      --prefix-clone    Clone prefix
      --uninstall       Uninstall operation

Notes:

  This script will use env variables:
    VHEX_VERBOSE            - verbose status
    VHEX_VERSION_BINUTILS   - target version of BINUTILS
    VHEX_VERSION_GCC        - target version of GCC
    VHEX_PREFIX_INSTALL     - installation prefix
    VHEX_PREFIX_SYSROOT     - sysroot prefix

  Default value for each configuration:
    VHEX_VERBOSE            - false
    VHEX_VERSION_BINUTILS   - lastest detected
    VHEX_VERSION_GCC        - lastest detected
    VHEX_PREFIX_INSTALL     - "~/.local/bin/"
    VHEX_PREFIX_CLONE       - "~/.local/share/sh-elf-vhex"
    VHEX_PREFIX_SYSROOT     - "~/.local/share/sh-elf-vhex/sysroot"
OEF
  exit 0
}

#---
# Parse arguments
#---

action='install'
VHEX_VERBOSE=false
VHEX_PREFIX_INSTALL=~/.local/bin
VHEX_PREFIX_SYSROOT=~/.local/share/sh-elf-vhex/sysroot
VHEX_PREFIX_CLONE=~/.local/share/sh-elf-vhex

for arg; do
  case "$arg" in
    --help    | -h)     help;;
    --verbose | -v)     VHEX_VERBOSE=true;;
    --prefix-install=*) VHEX_PREFIX_INSTALL=${arg#*=};;
    --prefix-sysroot=*) VHEX_PREFIX_SYSROOT=${arg#*=};;
    --uninstall)        action='uninstall';;
    *)
      echo "error: unreconized argument '$arg', giving up." >&2
      exit 1
  esac
done

#---
# Preliminary check
#---

if [ -d "$VHEX_PREFIX_CLONE" ]; then
  echo "It seems that the project is already existing :pouce:" >&2
  echo \
    'If you realy want to install this project remove the folder' \
    "'$VHEX_PREFIX_CLONE'"
  exit 1
fi

_src=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$_src/_utils.sh"

VHEX_VERSION_GCC=$(utils_find_last_version "$_src/../patches/gcc")
VHEX_VERSION_BINUTILS=$(utils_find_last_version "$_src/../patches/binutils")

if [[ "$VHEX_VERBOSE" == 'true' ]]
then
  echo "Debug fetched information:"
  echo " - VHEX_VERBOSE          = $VHEX_VERBOSE"
  echo " - VHEX_VERSION_BINUTILS = $VHEX_VERSION_BINUTILS"
  echo " - VHEX_VERSION_GCC      = $VHEX_VERSION_GCC"
  echo " - VHEX_PREFIX_INSTALL   = $VHEX_PREFIX_INSTALL"
  echo " - VHEX_PREFIX_SYSROOT   = $VHEX_PREFIX_SYSROOT"
  echo " - VHEX_PREFIX_CLONE     = $VHEX_PREFIX_CLONE"
fi

if [[ "$action" == 'install' ]]
then
  echo 'The script will install the sh-elf-vhex compiler with:'
  echo " - GCC version:           $VHEX_VERSION_GCC"
  echo " - Binutils version:      $VHEX_VERSION_BINUTILS"
  echo " - Clone directory:       $VHEX_PREFIX_CLONE"
  echo " - Compliler install at:  $VHEX_PREFIX_INSTALL"
  read -p 'Process ? [yN]: ' -r valid
else
    read -p 'Uninstall the sh-elf-vhex compiler ? [yN]: ' -r valid
fi
if [[ "$valid" != 'y' ]]; then
  echo 'Operation aborted o(x_x)o'
  exit 1
fi

#---
# Perform install operation
#---

git clone \
  --depth=1 \
  https://github.com/YannMagnin/sh-elf-vhex.git \
  "$VHEX_PREFIX_CLONE"

cd "$VHEX_PREFIX_CLONE" || exit 1

export VHEX_VERSION_BINUTILS
export VHEX_VERSION_GCC
export VHEX_VERBOSE
export VHEX_PREFIX_INSTALL
export VHEX_PREFIX_SYSROOT
export VHEX_PREFIX_CLONE

success='true'
if [[ "$action" == 'install' ]]
then
  ./scripts/binutils/configure.sh \
  && ./scripts/binutils/build.sh \
  && ./scripts/gcc/configure.sh \
  && ./scripts/gcc/build.sh \
  && ./scripts/_install.sh \
  || success='false'
  if [[ "$success" == 'true' ]]
  then
      echo 'Error during bootstraping operation' >&2
      exit 1
  fi
  echo 'Successfully installed sh-elf-vhex !'
  echo "Do not forget to export the binary path '$VHEX_PREFIX_INSTALL'"
else
  ./scripts/_uninstall.sh || success='false'
  if [[ "$success" != 'true' ]]
  then
    echo 'Error during unstallation step, abord' >&2
    exit 1
  fi
  echo 'Successfully uninstalled sh-elf-vhex'
fi
