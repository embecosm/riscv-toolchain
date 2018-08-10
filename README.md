Embecosm RISC-V Toolchain for testing OpenOCD with the GDB test suite
=====================================================================

This repository consists of scripts and related files for building a RISC-V tool
chain to test OpenOCD with the GDB test suite. Currently, this repository is
set up to run on specific hardware boards.

The default build is for RV32I. However, the architecture and ABI can be
modified.

Supported boards
----------------

SiFive Freedom E310 Arty FPGA image
SiFive Dual Core E31 Arty FPGA image

Getting the sources
-------------------

Use the `clone-all.sh` script in this directory to check out various
repositories alongside this one. To clone for read only access use:

```
./clone-all.sh
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

Building the tool chain
-----------------------

To build a 32-bit riscv32imac tool chain (binutils, gdb, gcc, newlib, etc.):

```
./build-tools.sh --with-arch=rv32imac
```

To see the options for `build-tools.sh`, use `./build-tools.sh --help`.
These include options for setting the architecture and ABI.

Executing the GDB tests
-----------------------


