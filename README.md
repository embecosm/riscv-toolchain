RISC-V Toolchain build
======================

Please note: The instructions below are primarily for building and testing riscv32ima.


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

Executing the GCC tests 
-----------------------

To run using the GDB simulator (the default):

```
./run-tests.sh
```

To run with the SPIKE ISA simulator, which should be on your PATH:
```
./run-spike-tests.sh
```

