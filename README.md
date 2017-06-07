Embecosm RISC-V Toolchain
=========================

This repository consists of scripts and related files for building and testing a
RISC-V Toolchain. The main differences of this toolchain build from the RISC-V
Foundation's riscv-tools and riscv-gnu-toolchain builds are:

- This repository uses upstream Binutils and GCC. Once other components are
  merged upstream (e.g. GDB, Newlib...) are merged upstream, this repository
  will be updated to use the upstream versions of those components.
- Only Newlib builds are supported, for bare-metal systems. There is no Linux
  support at present.
- The default build is for RV32IMA. However, the architecture and ABI can be
  modified.

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

NOTE: As of May 31st 2017, the GDB repository is in a transitional state
and doesn't build, so you will need to roll back to a working commit as follows:
```
cd ../gdb
git reset --hard 1135e18e7dc6ce046e423ad1d8ad3897ba9b562a
```

Building the toolchain
----------------------

NOTE: The device-tree-compiler package is required to build riscv-isa-sim
(SPIKE).

To build a 32-bit riscv32ima toolchain (binutils, gdb, gcc, newlib, SPIKE, etc.):

```
./build-all.sh
```

To see the options for `build-all.sh`, use `./build-all.sh --help`. These
include options for setting the architecture and ABI.


Executing the GCC tests
-----------------------

To run using the SPIKE ISA simulator:

```
./run-tests.sh
```

To run with the GDB simulator:
```
TARGET_BOARD=riscv-sim ./run-spike-tests.sh
```

