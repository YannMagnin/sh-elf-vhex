#! /usr/bin/env bash

#---
# Help screen
#---

function help()
{
  cat << EOF
Script for the uninstallation of the Vhex kernel's binutils.

Usage $0 [options...]

Configurations:
  -h, --help            Display this help
EOF
  exit 0
}

#---
# Parse arguments
#---

for arg
  do case "$arg" in
    --help | -h) help;;
    *)
      echo "error: unreconized argument '$arg', giving up." >&2
      exit 1
  esac
done


#---
# Unistall step
#---

source ../scripts/_utils.sh

TAG='<sh-elf-vhex>'
PREFIX=$(utils_get_env 'VHEX_PREFIX_INSTALL' 'install')
SYSROOT=$(utils_get_env 'VHEX_PREFIX_SYSROOT' 'sysroot')

# Check that all tools has been generated

if [[ ! -f "$SYSROOT/bin/sh-elf-vhex-gcc" ]]
then
  echo 'error: Are you sure to have built sh-elf-vhex ? it seems that' >&2
  echo '  Missing '\''gcc'\'' tool...' >&2
  exit 1
fi

#---
# Remove symlinks
#---

echo "$TAG Removing symlinks to binaries..."
for x in "$SYSROOT"/bin/*; do
  unlink "$PREFIX/$x"
done

#---
# Remove sysroot
#---

echo "$TAG Removing installed files..."
rmdir "$SYSROOT"
