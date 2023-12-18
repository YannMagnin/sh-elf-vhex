#!/usr/bin/env bash

#---
# Help screen
#---

function help() {
  cat << EOF
Bootstrap script used to install or uninstall the sh-elf-vhex compiler.

Usage $0 [options...]

Options:
  -h, --help            Display this help
  -v, --verbose         Display extra information during operation
      --prefix-install  Installation (bin) prefix
      --prefix-sysroot  Sysroot (lib, header, ...) prefix
      --prefix-clone    Clone prefix
      --overwrite       Remove the cloned version if exists and install
      --uninstall       Uninstall operation

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

action='install'
verbose='false'
overwrite='false'
prefix_install=~/.local/bin
prefix_sysroot=~/.local/share/sh-elf-vhex/_sysroot
prefix_clone=~/.local/share/sh-elf-vhex

for arg; do
  case "$arg" in
    --help    | -h)     help;;
    --verbose | -v)     verbose=true;;
    --prefix-install=*) prefix_install=${arg#*=};;
    --prefix-sysroot=*) prefix_sysroot=${arg#*=};;
    --prefix-clone=*)   prefix_clone=${arg#*=};;
    --uninstall)        action='uninstall';;
    --overwrite)        overwrite='true';;
    *)
      echo "error: unrecognized argument '$arg', giving up." >&2
      exit 1
  esac
done

#---
# Handle self-clone if needed
#---

# export verbose now to handle the self-clone if needed
[[ "$verbose" == 'true' ]] && export VERBOSE=1

_src=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$_src" || exit 1

if [[ "$prefix_clone/scripts" != "$_src" ]]
then
  if [[ -d "$prefix_clone" && "$overwrite" != 'true' ]]
  then
    echo -e \
      "It seems that the project is already existing :pouce:\n" \
      'If you really want to reinstall this project use the "--overwrite"' \
      'option.'
    exit 1
  fi
  [[ -d "$prefix_clone" ]] && rm -rf "$prefix_clone"
  echo '<sh-elf-vhex> self-clone repository...'
  git \
    clone \
    --depth=1 \
    https://github.com/YannMagnin/sh-elf-vhex.git \
    "$prefix_clone"
fi

cd "$prefix_clone/scripts" || exit 1
source ./_utils.sh

#---
# Preliminary checks
#---

version_gcc=$(utils_find_last_version ../patches/gcc)
version_binutils=$(utils_find_last_version ../patches/binutils)

if [[ "$verbose" == 'true' ]]
then
  echo "Debug fetched information:"
  echo " - VHEX_VERBOSE          = $verbose"
  echo " - VHEX_VERSION_BINUTILS = $version_binutils"
  echo " - VHEX_VERSION_GCC      = $version_gcc"
  echo " - VHEX_PREFIX_INSTALL   = $prefix_install"
  echo " - VHEX_PREFIX_SYSROOT   = $prefix_sysroot"
  echo " - VHEX_PREFIX_CLONE     = $prefix_clone"
fi

if [[ "$action" == 'install' ]]
then
  echo 'The script will install the sh-elf-vhex compiler with:'
  echo " - GCC version:           $version_gcc"
  echo " - Binutils version:      $version_binutils"
  echo " - Clone directory:       $prefix_clone"
  echo " - Compliler install at:  $prefix_install"
  read -p 'Process ? [yN]: ' -r valid
else
    read -p 'Uninstall the sh-elf-vhex compiler ? [yN]: ' -r valid
fi

# check if the stdin exists, which is not the case when the script is piped
# with bash (cat ./script/bootstrap.sh | bash)
if [[ -t 0 ]]
then
  if [[ "$valid" != 'y' ]]; then
  echo 'Operation aborted o(x_x)o'
  exit 1
  fi
fi

#---
# Performs install/uninstall operation
#---

if [[ "$action" == 'install' ]]
then
  {
    ./binutils/configure.sh     \
        --prefix-sysroot="$prefix_sysroot"    \
        --version="$version_binutils"         \
    && ./binutils/build.sh      \
    && ./gcc/configure.sh       \
        --prefix-sysroot="$prefix_sysroot"    \
        --version="$version_gcc"              \
    && ./gcc/build.sh           \
    && ./_install.sh            \
        --prefix-sysroot="$prefix_sysroot"    \
        --prefix-install="$prefix_install"
  } || {
      echo 'Error during bootstraping operations' >&2
      exit 1
  }
  echo 'Successfully installed sh-elf-vhex !'
  echo "Do not forget to export the binary path '$prefix_install'"
else
  {
    ./_uninstall.sh                         \
        --prefix-sysroot="$prefix_sysroot"  \
        --prefix-install="$prefix_install"  \
        --prefix-clone="$prefix_clone"      \
        --purge
  } || {
    echo 'Error during uninstallation step, abort' >&2
    exit 1
  }
  echo 'Successfully uninstalled sh-elf-vhex'
fi
