Embecosm RISC-V Toolchain - code size comparison branch
=======================================================

This repository consists of scripts and related files for comparing code size
across RISC-V, ARM, and ARC.

This is presently a work-in-progress.

Obtaining sources
-----------------

First clone this repository, then use the `clone-all.sh` script to clone all
other sources alongside this repository:

```
git clone -b grm-compare-wip git@github.com:embecosm/riscv-toolchain.git
cd riscv-toolchain
./clone-all.sh
```

Building
--------

To build the RISC-V toolchain and QEMU, use

```
./build-all.sh [--with-xlen <xlen>]
               [--with-arch <arch>]
               [--with-abi  <abi>]
```

All arguments are optional, the defaults being to build a toolchain for `rv32imc`
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
