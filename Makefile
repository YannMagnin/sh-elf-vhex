
VERSION_BINUTILS	:= 2.37
VERSION_GCC		:= 11.2.0

configure:
	@ cd ./scripts/binutils \
		&& ./configure.sh --version="$(VERSION_BINUTILS)" \
		&& cd ../gcc && ./configure.sh --version="$(VERSION_GCC)"

build:
	@ cd ./scripts/binutils && ./build.sh && cd ../gcc && ./build.sh

install:
	@ cd ./scripts/binutils \
		&& ./install.sh --prefix="$(PREFIX)" \
		&& cd ../gcc && ./install.sh --prefix="$(PREFIX)"

uninstall:
	@ cd ./scripts/binutils \
		&& ./uninstall.sh --prefix="$(PREFIX)" \
		&& cd ../gcc && ./uninstall.sh --prefix="$(PREFIX)"

.PHONY: configure build install uninstall
