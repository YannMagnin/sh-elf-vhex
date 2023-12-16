#! /usr/bin/env bash

#---
# Help screen
#---

function help()
{
  cat << EOF
Script for the uninstallation of sh-elf-vhex

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
      --prefix-install  Installation (bin) prefix
      --prefix-sysroot  Sysroot (lib, header, ...) prefix
      --prefix-clone    Clone prefix
      --purge           Remove the clonned folder
EOF
  exit 0
}

#---
# Parse arguments
#---

prefix_install=''
prefix_sysroot=''
prefix_clone=''
purge='false'
for arg
  do case "$arg" in
    --help | -h)        help;;
    --purge)            purge='true';;
    --prefix-install=*) prefix_install=${arg#*=};;
    --prefix-sysroot=*) prefix_sysroot=${arg#*=};;
    --prefix-clone=*)   prefix_clone=${arg#*=};;
    *)
      echo "error: unreconized argument '$arg', giving up." >&2
      exit 1
  esac
done

#---
# Preliminary check
#---

if [[ -z "$prefix_install" || -z "$prefix_sysroot" || -z "$prefix_clone" ]]
then
  echo 'Missing prefix information, abord' >&2
  exit 1
fi

if [[ ! -f "$prefix_sysroot/bin/sh-elf-vhex-as" ]]
then
  echo 'error: Are you sure to have built sh-elf-vhex ? it seems that' >&2
  echo '  Missing '\''sh-elf-vhex-as'\'' tool...' >&2
  exit 1
fi

#---
# Unistall step
#---

_src=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$_src" || exit 1
source ./_utils.sh

echo "$TAG Removing symlinks to binaries..."
for x in "$prefix_sysroot"/bin/*; do
  utils_callcmd unlink "$x"
  utils_callcmd unlink "$prefix_install/$(basename "$x")"
done

echo "$TAG Removing sysroot..."
rm -rf "$prefix_sysroot"

if [[ "$purge" == 'true' ]]
then
  echo "$TAG removing cloned folder..."
  rm -rf "$prefix_clone"
fi
