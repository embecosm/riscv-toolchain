RISC-V Toolchain build
======================

Repositories checked out alongside the toolchain repo should be:

- binutils from git://sourceware.org/git/binutils-gdb.git
- gdb from git@github.com:riscv/riscv-binutils-gdb
- gcc from git@github.com:gcc-mirror/gcc
- newlib from https://github.com/riscv/riscv-newlib.git
- dejagnu from git@github.com:riscv/riscv-dejagnu.git

Building the toolchain
----------------------

Execute:

```
./build-all.sh
```

Executing the GCC tests
-----------------------

```
./run-tests.sh
```
