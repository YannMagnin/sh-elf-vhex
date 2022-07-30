
VERSION_BINUTILS	:= 2.37
VERSION_GCC		:= 11.2.0

ifeq ($(VXSDK_PREFIX_INSTALL),)
$(error you need to use the vxSDK to compile this package)
endif

configure:
	@ cd ./scripts/binutils \
		&& ./configure.sh --version="$(VERSION_BINUTILS)" \
		&& cd ../gcc && ./configure.sh --version="$(VERSION_GCC)"

build:
	@ cd ./scripts/binutils && ./build.sh && cd ../gcc && ./build.sh

install:
	@ cd ./scripts/binutils \
		&& ./install.sh --prefix="$(VXSDK_PREFIX_INSTALL)" \
		&& cd ../gcc && ./install.sh --prefix="$(VXSDK_PREFIX_INSTALL)"

uninstall:
	@ cd ./scripts/binutils \
		&& ./uninstall.sh --prefix="$(VXSDK_PREFIX_INSTALL)" \
		&& cd ../gcc && ./uninstall.sh --prefix="$(VXSDK_PREFIX_INSTALL)"

.PHONY: configure build install uninstall
