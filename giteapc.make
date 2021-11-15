# giteapc: version=1

PREFIX ?= $(GITEAPC_PREFIX)
VERSION_BINUTILS := 2.37
VERSION_GCC := 11.2

-include giteapc-config.make

configure:
	@ ./scripts/binutils/configure --version=$(VERSION_BINUTILS)
	@ ./scripts/gcc/configure.sh --version=$(VERSION_GCC)

build:
	@ ./scripts/binutils/build.sh
	@ ./scripts/gcc/build.sh

install:
	@ ./scripts/binutils/install.sh --prefix="$(PREFIX)"
	@ ./scripts/gcc/install.sh --prefix="$(PREFIX)"

uninstall:
	@ ./scripts/binutils/uninstall.sh --prefix="$(PREFIX)"
	@ ./scripts/gcc/uninstall.sh --prefix="$(PREFIX)"

.PHONY: configure build install uninstall
