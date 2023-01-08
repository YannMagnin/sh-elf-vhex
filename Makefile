#---
# This makefile is particular because it can be involved many time during the
# building process. This is why we using many conditional rule exposition
#
# All possible scenarii are :
# * sh-elf-vhex -> fxlibc -> OpenLibM -> sh-elf-vhex
# * sh-elf-vhex -> fxlibc -> sh-elf-vhex
# * fxlibc -> sh-elf-vhex -> fxlibc -> sh-elf-vhex
# * OpenLibM -> sh-elf-vhex -> fxlibc -> OpenLibM -> sh-elf-vhex
#---

VERSION_BINUTILS := 2.38
VERSION_GCC      := 11.3.0


# check that the vxSDK is used

ifeq ($(VXSDK_PREFIX_INSTALL),)
$(error you need to use the vxSDK to compile this package)
endif

# default rules

all: build install

#---
# Performs the real operations
#---

ifeq ($(VXSDK_COMPILER_CIRCULAR_BUILD_WORKAROUND),)
build:
	@ cd ./scripts/binutils && ./configure.sh --version="$(VERSION_BINUTILS)"
	@ cd ./scripts/binutils && ./build.sh
	@ cd ./scripts/gcc && ./configure.sh --version="$(VERSION_GCC)"
	@ cd ./scripts/gcc && ./build.sh

install:
	@ cd ./scripts && ./install.sh --prefix="$(VXSDK_PREFIX_INSTALL)"

uninstall:
	@ cd ./scripts && ./uninstall.sh --prefix="$(VXSDK_PREFIX_INSTALL)"

#---
# If a circular build is detected, simulate that all operations have
# successfully been executed
#---

else
build:
	@ true

install:
	@ true

uninstall:
	@ true

endif

.PHONY: all build install uninstall
