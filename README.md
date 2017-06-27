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

Prerequisites
-------------

As well as a standard developer tool chain, you will need the device tree
compiler.  On Ubuntu:
```
sudo apt install device-tree-compiler
```
or on Fedora:
```
sudo dnf install dtc
```

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
git reset --hard 80a1493
```
However the developers keep on rebasing so the commit number may change. You
need to be on the default branch, which is `riscv-next` _not_ `master`.  Then
look for a log entry:
```
Author: Palmer Dabbelt <palmer@dabbelt.com>
Date:   Thu May 18 18:08:25 2017 -0700

    (WIP) RISC-V: Add R_RISCV_DELETE, which marks bytes for deletion

    We currently delete bytes by shifting an entire BFD backwards to
    overwrite the bytes we no longer need.  The result is that relaxing a
    BFD is quadratic time.

    This patch adds an additional relocation that specifies a byte range
    that will be deleted from the final object file, and adds a relaxation
    pass (between the existing passes that delete bytes and the alignment
    pass) that actually deletes the bytes.  Note that deletion is still
    quadratic time, and nothing uses R_RISCV_DELETE yet.

    R_RISCV_DELETE will never be emitted into ELF objects, so therefor isn't exposed
    to the rest of binutils.
```

Building the toolchain
----------------------

NOTE: The device-tree-compiler package is required to build riscv-isa-sim
(SPIKE) and verilator is required to build the PICORV32 GDB Server.

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
TARGET_BOARD=riscv-sim ./run-tests.sh
```

To run with the GDB Server for PICORV32:

```
TARGET_BOARD=riscv-gdbserver ./run-tests.sh
```
