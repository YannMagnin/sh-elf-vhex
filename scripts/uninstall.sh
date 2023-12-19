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
      --no-purge        Do not remove the cloned folder
EOF
  exit 0
}

#---
# Parse arguments
#---

purge='true'
prefix_install=~/.local/bin
prefix_sysroot=~/.local/share/sh-elf-vhex/_sysroot
prefix_clone=~/.local/share/sh-elf-vhex
for arg
  do case "$arg" in
    --help | -h)        help;;
    --no-purge)         purge='false';;
    --prefix-install=*) prefix_install=${arg#*=};;
    --prefix-sysroot=*) prefix_sysroot=${arg#*=};;
    --prefix-clone=*)   prefix_clone=${arg#*=};;
    *)
      echo "error: unrecognized argument '$arg', giving up." >&2
      exit 1
  esac
done

#---
# Preliminary check
#---

if [[ ! -d "$prefix_clone" ]]
then
  echo -e \
    'Are you sure to have installed the project ?\n' \
    '\rIt seems that the cloned prefix does not exists' \
  >&2
  exit 1
fi

if [[ ! -d "$prefix_install" ]]
then
  echo -e \
    'WARNING: seems that the install prefix does not exists\n' \
    'WARNING: if you continue, the install prefix will be ignore and' \
    'nothing will be removed' \
  >&2
  read -p 'Proccess anyway ? [yN]' -r valid < /dev/tty
  if [[ "$valid" != 'y' ]]; then
    echo 'Operation aborted o(x_x)o' >&2
    exit 1
  fi
fi

if [[ ! -x "$prefix_sysroot/bin/sh-elf-vhex-as" ]]
then
  echo -e \
    'ERROR: Are you sure to have built sh-elf-vhex ? Seems that the' \
    'sh-elf-vhex-as cannot be found in the sysroot prefix' \
  >&2
  exit 1
fi

echo 'The script will uninstall the sh-elf-vhex compiler with:'
echo " - Clone directory:   $prefix_clone"
echo " - Install directory: $prefix_install"
echo " - Sysroot directory: $prefix_sysroot"
read -p 'Process ? [yN]: ' -r valid < /dev/tty
if [[ "$valid" != 'y' ]]
then
  echo 'Operation aborted o(x_x)o'
  exit 1
fi

#---
# Unistall step
#---

cd "$prefix_clone/scripts" || exit 1
source ./_utils.sh

echo "$TAG removing symlinks to binaries..."
for x in "$prefix_sysroot"/bin/*; do
  utils_callcmd unlink "$x"
  if [[ -L "$prefix_install/$(basename "$x")" ]]; then
    utils_callcmd unlink "$prefix_install/$(basename "$x")"
  fi
done

echo "$TAG removing sysroot..."
rm -rf "$prefix_sysroot"

if [[ "$purge" == 'true' ]]
then
  echo "$TAG removing cloned folder..."
  rm -rf "$prefix_clone"
fi
