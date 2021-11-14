#! /usr/bin/env bash

echo "Compil and install binutils"
cd binutils
./configure.sh --version=2.37 --prefix=/tmp \
&& ./build.sh \
&& ./install.sh --prefix=/tmp

echo "Compil and install GCC"
cd ../gcc
./configure.sh --version=11.2.0 --prefix=/tmp \
&& ./build.sh
#&& ./install.sh --prefix=/home/yann/CASIO/vhex-compiler/sh-elf-vhex/scripts
