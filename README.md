RISC-V Toolchain build
======================

Use the `clone-all.sh` script in this directory to check out various
repos alongside this one. To clone for read only access use:
```
./clone-all.sh
```
To clone for SSH write access to the Embecosm owned repos (you must have write
permission granted).
```
./clone-all.sh -dev
```

Building the toolchain
----------------------

Note that you require the device-tree-compiler package to build riscv-isa-sim
(SPIKE).

Execute:

```
./build-all.sh
```

Executing the GCC tests
-----------------------

```
./run-tests.sh
```
