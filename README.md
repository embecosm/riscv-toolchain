RISC-V Toolchain build
======================

Repositories can be checked out alongside the toolchain as follows:

```
git clone git://sourceware.org/git/binutils-gdb.git binutils
git clone ssh://git@github.com/riscv/riscv-binutils-gdb gdb
git clone ssh://git@github.com/gcc-mirror/gcc gcc
git clone ssh://git@github.com/riscv/riscv-newlib.git newlib
git clone ssh://git@github.com/riscv/riscv-dejagnu.git dejagnu
git clone https://github.com/embecosm/riscv-gdbserver.git gdbserver
```

or use the `clone-all.sh` script in this directory. To clone for read only
access use:
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

Execute:

```
./build-all.sh
```

Executing the GCC tests
-----------------------

```
./run-tests.sh
```
