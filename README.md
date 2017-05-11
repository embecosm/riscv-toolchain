RISC-V Toolchain build
======================

Repositories can be checked out alongside the toolchain as follows:

```
git clone git://sourceware.org/git/binutils-gdb.git binutils
git clone ssh://git@github.com/riscv/riscv-binutils-gdb gdb
git clone ssh://git@github.com/gcc-mirror/gcc gcc
git clone ssh://git@github.com/riscv/riscv-newlib.git newlib
git clone ssh://git@github.com/riscv/riscv-dejagnu.git dejagnu
```

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
