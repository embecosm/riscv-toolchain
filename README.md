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

Building the targets
--------------------

NOTE: verilator is required to build the PICOVR32 and RI5CY GDB Server

The tool chain and the targets are built separately. The targets
should be built first as the gdbserver needs to link against 
the generated PICORV32 and RI5CY verilator models.

To build the picorv32 and ri5cy verilator models:

```
./build-targets.sh
```

There are optional arguments `--ri5cy-source` and `picorv32-source`
which can be used to provide an alternative source directory to
for the respective targets. By default it is assumed that the
source is containing in `ri5cy` and `picorv32` directories in the
directory above the toolchain.

Building the tool chain
-----------------------

To build a 32-bit riscv32i tool chain (binutils, gdb, gcc, newlib, etc.):

```
./build-tools.sh
```

To see the options for `build-tools.sh`, use `./build-tools.sh --help`.
These include options for setting the architecture and ABI.

Building SPIKE
--------------

NOTE: The device-tree-compiler package is required to build riscv-isa-sim
(SPIKE).
NOTE: The tools should be built (eg by using the `build-tools.sh script),
before building the simulator.

To build spike for riscv32i :

```
./build-spike.sh
```

To see the options for `build-spike.sh`, use `./build-spike.sh --help`.
These include options for setting the target and architecture.

Building the ISA tests
----------------------

To build the ISA tests for the RISC-V

```
./build-isa-tests.sh
```

To see the options for `build-isa-tests.sh`, use
`./build-isa-tests.sh --help`.

Building testfloat
------------------

To build Berkeley TestFloat:

```
./build-testfloat.sh
```

To see the options for `build-testfloat.sh`, use `./build-testfloat.sh --help`.

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

Executing the RISC-V ISA tests
------------------------------

The test must be built before running the tests. They can be built
using the `build-isa-tests.sh` script.

To run with the GDB Server for RI5CY:

```
./run-isa-tests.sh
```

Or

```
./run-isa-tests --with-board riscv-ri5cy
```

To run with the GDB Server for PICORV32:

```
./run-isa-tests --with-board riscv-picorv32
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

