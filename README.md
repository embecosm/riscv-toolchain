Embecosm RISC-V Toolchain for Stack Erase
=========================================

This repository consists of scripts and related files for building and testing a
RISC-V tool chain with stack erase.

Obtaining sources
-----------------

First clone this repository, then use the `clone-all.sh` script to clone all
other sources alongside this repository:

```
git clone -b stack-erase git@github.com:embecosm/riscv-toolchain.git
cd riscv-toolchain
./clone-all.sh
```

Building
--------

To build the toolchain and ISA simulator, use

```
./build-all.sh [--with-xlen <xlen>]
               [--with-arch <arch>]
               [--with-abi  <abi>]
               [--enable-default-stack-erase]
```

All arguments are optional, the defaults being to build a toolchain for `rv32im`
with the `ilp32` ABI. Possible values are:

|Parameter  | Value                                          |
|-----------|------------------------------------------------|
| `xlen`    | `32` or `64`                                   |
| `arch`    | ISA and extensions, e.g. `i`, `im`, `gc`, etc. |
| `abi`     | `ilp32`, `lp64`, etc.                          |

Passing the argument `--enable-default-stack-erase` will result in a toolchain
where stack erase is on by default.

Executing the GCC tests
-----------------------

To run tests:

```
./run-tests.sh [--tool <tool>]
```

The default tool is `gcc` - however the `g++` and `libstdc++` tests can also be
run by specifying the `--tool` argument.
