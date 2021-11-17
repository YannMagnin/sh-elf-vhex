# sh-elf-vhex - modified GCC for the Vhex kernel projet

---

## Context

This project was born following the discovery of a limitation with GCC on the
SuperH architecture
(see on this subject from 2 years ago:
https://gcc.gnu.org/legacy-ml/gcc-help/current/000075.html).

The generation of dynamic libraries is blocked by GCC (the `--shared` flag is ignored),
because the `sh3eb-elf` target (the one used for cross-compiling on Casio calculators),
does not support this functionality.

I am currently building a kernel of a Casio's calculator for a graduation
project and I need this functionality. I had discovered, thanks to Lephenixnoir,
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

---

## Build

The build is relatively simple and can be done in two different ways: you can
use the `compile.sh` script which is at the root of the repository:

```bash
./compile /your/installation/path
```

Or you can use the `giteapc` tool, created by Lephenixnoir:

```bash
giteapc install sh-elf-vhex
```

It takes about twenty minutes for the build.

---

## Technical notes

The GCC build takes much longer than the `sh3eb-elf` target because we have two
stages for the GCC build. In order, we have:

* download + configuration of binutils sources
* download + configuration of GCC sources
* compilation of binutils
* compilation of GCC (stage-1) without enabling the shared library functionality
* compilation of OpenLibM (a dependency of our standard C library)
* compilation of fxlibc, our custom C standard library
* compilation of GCC (stage-2) with activation of the shared library fonctionality
* installation of our C library
* compilation of the shared libgcc

As for the details of the `sh-elf-vhex` target that we created:

* machine-specific features:
  * (`t-slibgcc`) compilation of the shared libgcc
  * (`t-libgcc-pic`) the compilation of the libgcc in PIC
  * (`t-fdpbit`) compilation of the library for emulated floating point numbers
* global configuration:
  * only C is supported
  * only big endian encoding is supported
  * we use the stdint header from `newlib`. Otherwise, the generation of `stdint.h` is incomplete
  * we only target the SH4A-NOFPU processor (no backward compatibility with the SH3 assembler)
  * each public symbol begins with an underscore
  * by default, we link our own C library to each generation of an object file
  * we do not provide a specialized default linker script (for the moment)

---

## Special thanks

A big thanks to Lephenixnoir who helped me a lot for the modification of the
sources and made this project possible!
