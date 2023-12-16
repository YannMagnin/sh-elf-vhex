# sh-elf-vhex - modified GCC for the Vhex kernel projet

## Context

This project was born following the discovery of a limitation with GCC on the
SuperH architecture
[see on this subject from 2 years ago](
https://gcc.gnu.org/legacy-ml/gcc-help/current/000075.html
):

The generation of dynamic libraries is blocked by GCC (the `--shared` flag is ignored),
because the `sh3eb-elf` target (the one used for cross-compiling on Casio calculators),
does not support this functionality.

I am currently building a kernel for Casio's calculator for a graduation
project and I need this functionality. I had discovered, thanks to
[Lephenixnoir](https://silent-tower.net/research/),
that we could generate 'shared' libraries by using directly `ld` with a custom
linker script, but this workaround was of short duration. Indeed, we are
dependent on a library called `libgcc`, which provide some useful critical
primitives and which is generated only statically (therefore with
non-relocatable code), which broke all shared object file generated with this
dependencie (and a lot of cases can involve this librarie).

With the help of Lephenixnoir, we tried to add a target for the
superH architecture called `sh-elf-vhex`, allowing us to enable these features
and that's what we finally came up with.

This repository gathers only the files that we had to modify for
`binutils` and` GCC`, as well as scripts to automate the installation of this
particular GCC.

## Technical notes

As for the details of the `sh-elf-vhex` target that we created:

  * only C is supported
  * only big endian encoding is supported
  * we use the stdint header from `newlib`. Otherwise, the generation of `stdint.h` is incomplete
  * we only target the SH4A-NOFPU processor (no backward compatibility with the SH3 assembler)
  * each public symbol begins with an underscore
  * by default, we link our own C library to each generation of an object file
  * we do not provide a specialized default linker script (for the moment)

## Installing

The build is relatively simple and can be done in two different ways:

```bash
curl -s "https://github.com/YannMagnin/sh-elf-vhex/+/HEAD/scripts/bootstrap.sh?format=TEXT" | base64 --decode | bash
```

Or by cloning the project and using the `bootstrap.sh` script, see
`./scripts/bootstrap.sh --help` for more information about possible operation
you can do with it (like uninstalling the compiler)

```bash
cd /tmp/
git clone 'https://github.com/YannMagnin/sh-elf-vhex.git' --depth=1
cd /tmp/sh-elf-vhex || exit 1
./script/bootstrap.sh
```

It takes about twenty minutes for the build.

## Supported version list

Note that GCC `12.x` will never be supported since many critical bugs has been
found for the superh backend
(https://gcc.gnu.org/bugzilla/show\_bug.cgi?id=106609)

- GCC `11.2.0` and binutils `2.31`

## Special thanks

A big thanks to [Lephenixnoir](https://silent-tower.net/research/) who helped
me a lot for the modification of the sources and made this project possible!
