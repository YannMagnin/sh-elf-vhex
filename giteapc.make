# giteapc: version=1

PREFIX ?= $(GITEAPC_PREFIX)
VERSION_BINUTILS = 2.37
VERSION_GCC = 11.2

-include giteapc-config.make

configure:
	@ ./configure.sh --binutils $(VERSION_BINUTILS) "$(PREFIX)"
	@ ./configure.sh --gcc $(VERSION_GCC) "$(PREFIX)"

build:
	@ ./build.sh --binutils
	@ ./build.sh --gcc

install:
	@ ./install.sh --binutils "$(PREFIX)"
	@ ./install.sh --gcc "$(PREFIX)"

uninstall:
	@ ./uninstall.sh --binutils "$(PREFIX)"
	@ ./uninstall.sh --gcc "$(PREFIX)"

.PHONY: configure build install uninstall
