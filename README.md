# sh-elf-vhex - v2.2.2

Modified GCC for the Vhex kernel projet

## Context

This project was born following the discovery of a limitation with GCC on the
SuperH architecture
[see on this subject from few years ago](
https://gcc.gnu.org/legacy-ml/gcc-help/current/000075.html
):

The generation of dynamic libraries is blocked by GCC (the `--shared` flag is
ignored), because the `sh3eb-elf` target (the one used for cross-compiling on
Casio calculators), does not support this functionality.

I am currently building a kernel for Casio's calculator for a graduation
project and I need this functionality. I had discovered, thanks to
[Lephenixnoir](https://silent-tower.net/research/),
that we could generate 'shared' libraries by using directly `ld` with a custom
linker script, but this workaround was of short duration. Indeed, we are
dependent on a library called `libgcc`, which provides some useful critical
primitives and is generated only in static (therefore with
non-relocatable code) which breaks all shared object files generated with this
dependency (and a lot of cases can involve this library).

With the help of Lephenixnoir, we tried to add a target for the
superH architecture called `sh-elf-vhex`, allowing us to enable these features
and that's what we finally came up with.

This repository gathers only the files that we had to modify for
`binutils` and` GCC`, as well as scripts to automate the installation of this
particular GCC.

## Features/Limitations

* only C is supported
* only big endian encoding is supported
* we use the `stdint` header from `newlib`. Otherwise, the generation of `stdint.h` is incomplete
* we only target the `SH4A-NOFPU` processor (no backward compatibility with the SH3 assembler)
* each public symbol begins with an underscore
* by default, we link our own C library to each generation of object files
* we do not provide a specialized default linker script (for the moment)
* compilation of the shared libgcc (`t-slibgcc`)
* compilation of the libgcc in PIC (`t-libgcc-pic`)
* compilation of the library for emulated floating point numbers (`t-softfp`)

## Installing

The build is relatively simple and can be done in two different ways:

Using `curl`:
```bash
curl -fsSL https://raw.githubusercontent.com/YannMagnin/sh-elf-vhex/HEAD/scripts/install.sh | bash
```

Note that you can do the uninstallation using `curl` too:
```bash
curl -fsSL https://raw.githubusercontent.com/YannMagnin/sh-elf-vhex/HEAD/scripts/uninstall.sh | bash
```

Or by cloning the project and using the `install.sh` script, see
`./scripts/install.sh --help` for more information about possible operations
you can do with it

```bash
cd /tmp/
git clone 'https://github.com/YannMagnin/sh-elf-vhex.git' --depth=1
cd /tmp/sh-elf-vhex || exit 1
./script/install.sh
```

It takes about twenty minutes for the build.

Do not forget to add the install prefix (`~/.local/bin`) path to your `PATH`
environment variable:

> [!WARNING]
> You must add the absolute path to your PATH environment variable

```bash
# *unix-like
export PATH="$PATH:/home/<your_login>/.local/bin"

# macos (darwin-like)
export PATH="$PATH:/Users/<your_login>/.local/bin"
```

## Supported version list

Note that GCC `12.x` will never be supported since many critical bugs have
been found for the superh backend
(https://gcc.gnu.org/bugzilla/show_bug.cgi?id=106609)

- GCC `14.1.0` and binutils `2.42`
- GCC `13.2.0` and binutils `2.41`
- GCC `11.2.0` and binutils `2.31`

## Technical notes

The bootstrap process will clone this repository at
`~/.local/share/sh-elf-vhex` then will start the installation using:

* `prefix-clone` = `~/.local/share/sh-elf-vhex`
* `prefix-sysroot` = `~/.local/share/sh-elf-vhex/_sysroot`
* `prefix-install` = `~/.local/bin/`

The project also automatically installs
[vxOpenLibm](https://github.com/YannMagnin/vxOpenLibm)
and [vxLibc](https://github.com/YannMagnin/vxLibc)



## Special thanks

A big thanks to [Lephenixnoir](https://silent-tower.net/research/) who helped
me a lot for the modification of the sources and made this project possible!
