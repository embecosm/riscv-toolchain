Embecosm RISC-V Toolchain
=========================

This repository consists of scripts and related files for building and testing a
RISC-V tool chain. The main differences of this tool chain build from the RISC-V
Foundation's riscv-tools and riscv-gnu-toolchain builds are:

- This repository uses upstream Binutils and GCC. Once other components are
  merged upstream (e.g. GDB, Newlib...) are merged upstream, this repository
  will be updated to use the upstream versions of those components.
- Only Newlib builds are supported, for bare-metal systems. There is no Linux
  support at present.
- The default build is for RV32I. However, the architecture and ABI can be
modified.

Prerequisites
-------------

The Ri5cy and PivoRV32 verilator models require verilator version >=3.906.
Versions >=3.884 may also work but are untested.

Getting the sources
-------------------

Use the `clone-all.sh` script in this directory to check out various
repositories alongside this one. To clone for read only access use:

```
./clone-all.sh
```

To clone for SSH write access to the Embecosm owned repos (you must have write
permission granted).

```
./clone-all.sh -dev
```

Updating the source
-------------------

The `checkout-all.sh` script can be used to checkout the known good branches
for each repository

```
./checkout-all.sh
```

There is an optional argument, `--pull`  to pull the latest code for each branch

```
./checkout-all.sh --pull
```

Using a particular version of the source
----------------------------------------

The `checkout-tag.sh` script can be used to checkout a particular tag for each
repository

```
./checkout-all.sh  mytag
```

checks out the `mytag` tag on each branch.

Building the tool chain
-----------------------

NOTE: The device-tree-compiler package is required to build riscv-isa-sim
(SPIKE) and verilator is required to build the PICORV32 GDB Server.

To build a 32-bit riscv32i tool chain (binutils, gdb, gcc, newlib, SPIKE,
etc.):

```
./build-all.sh
```

To see the options for `build-all.sh`, use `./build-all.sh --help`. These
include options for setting the architecture and ABI.

Building the ISA tests
----------------------

To build the ISA tests for the RISC-V

```
./build-isa-tests.sh
```

To see the options for `build-all-isa.sh`, use `./build-all-isa.sh --help`.

Executing the GCC tests
-----------------------

To run with the GDB simulator:

```
./run-tests.sh
```

To run with the GDB Server for RI5CY:
```
./run-tests.sh --with-board riscv-ri5cy
```

To run with the GDB Server for PICORV32:

```
./run-tests.sh --with-board riscv-picorv32
```

Tagging the tool chain
----------------------

There is a convenience script for developers, `tag-all.sh` which can be used
to tag the currently checked out points of every repository.  You must have
write access to the Embecosm organization for this to work.

```
tag-all.sh mytag "An example tag"
```

Will apply the `mytag` tag to all repositories, with the associated message
"An example tag".

