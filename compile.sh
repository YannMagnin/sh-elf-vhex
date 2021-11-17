#! /usr/bin/env bash

# check mandatory args
if [[ $# -eq 0 ]]; then
  echo "missing install path prefix !" >&2
  exit 1
fi

cd scripts/binutils
./configure.sh --version=2.37 && ./build.sh && ./install.sh --prefix="$1"

cd ../gcc
./configure.sh --version=11.2.0 && ./build.sh && ./install.sh --prefix="$1"
