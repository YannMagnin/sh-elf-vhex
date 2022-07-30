# giteapc: version=1

VERSION_BINUTILS := 2.37
VERSION_GCC := 11.2.0

# Try to find if the file is involved by giteapc or vxsdk
ifeq ($(GITEAPC_PREFIX),)
PREFIX ?= $(VXSDK_PREFIX_INSTALL)
endif
ifeq ($(VXSDK_PREFIX_INSTALL),)
PREFIX ?= $(GITEAPC_PREFIX)
endif

configure:
	@ cd ./scripts/binutils && ./configure.sh --version=$(VERSION_BINUTILS)
	@ cd ./scripts/gcc && ./configure.sh --version=$(VERSION_GCC)

build:
	@ cd ./scripts/binutils && ./build.sh
	@ cd ./scripts/gcc && ./build.sh

install:
	@ cd ./scripts/binutils && ./install.sh --prefix="$(PREFIX)"
	@ cd ./scripts/gcc && ./install.sh --prefix="$(PREFIX)"

uninstall:
	@ cd ./scripts/binutils && ./uninstall.sh --prefix="$(PREFIX)"
	@ cd ./scripts/gcc && ./uninstall.sh --prefix="$(PREFIX)"

.PHONY: configure build install uninstall
