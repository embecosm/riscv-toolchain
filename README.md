ORConf RISC-V Toolchain Quick Start
===================================

This Quick Start provides a short intro to allow you to do the following:

- Build the tools and models
- Run the BEEBS benchmarks to get cycle counts as presented at ORConf
- Run the GCC Testsuite to get the test results as presented at ORConf
- Build a "Hello world" program for RISC-V and execute it on the RI5CY model


Building the tools and models
-----------------------------

In addition to standard development tools, you will need Verilator 3.906 and it
should be on the pkg-config path. 

To build the models and toolchain, first clone the toolchain repository:

```
git clone git@github.com:embecosm/riscv-toolchain.git toolchain
```

Then clone other repos, checkout branches, and build the models and tools:

```
cd toolchain
./clone-all.sh
./checkout-all.sh --pull
./build-targets.sh
./build-tools.sh
```


Benchmarking with BEEBS
-----------------------

To build BEEBS for PicoRV32:

```
cd ..
export PATH=`pwd`/install/bin:$PATH
cd beebs
./configure --host=riscv32-unknown-elf --with-chip=picorv32 --with-board=picorv32verilator --disable-maintainer-mode
make
```

Run the benchmarks with:

```
./picorv32count.py
```

The output is a comma-separated tuple of benchmark name, cycle count, and exit
code. Negative cycle counts and exit codes indicate a timeout. Positive exit
codes indicate a self-check error.

The experiments can then be repeated for RI5CY by first cleaning and rebuilding:

```
make clean
./configure --host=riscv32-unknown-elf --with-chip=ri5cy --with-board=ri5cyverilator --disable-maintainer-mode
make
```

Then run the benchmarks on RI5CY:

```
./ri5cycount.py
```

The output format is the same as for the PicoRV32 script.


Running the GCC regression test suite
-------------------------------------

The GCC regression tests can be run from the toolchain directory either with:

```
./run-tests.sh --with-board riscv-picorv32 --tool gcc
```

or

```
./run-tests.sh --with-board riscv-ri5cy --tool gcc
```

depending on which core you'd like to run the tests.

The GCC test output is placed in
`${toolchain_dir}/../build/gcc-stage-2/gcc/testuite/gcc`. You can see the sumary
at the end of the gcc.sum file, e.g.:

```
                === gcc Summary ===

# of expected passes            86842
# of unexpected failures        27
# of unexpected successes       4
# of expected failures          147
# of unresolved testcases       189
# of unsupported tests          2540
```


Building and running a "Hello World" application
------------------------------------------------

The whole toolchain is installed in the `install/bin` directory next to the
toolchain directory. Add it to the path, whilst in the folder above the
toolchain folder:

```
export PATH=`pwd`/install/bin:$PATH
```

Write a typical "Hello World" program:

```
#include <stdio.h>

int main(void)
{
  printf("Hello from RI5CY\n");
  return 0;
}
```

Build it with:

```
riscv32-unknown-elf-gcc hello.c -o hello
```

Loading and running of programs is done with GDB talking to the GDBServer.
Launch GDB with:

```
riscv32-unknown-elf-gdb hello
```

To start and connect to the GDBServer, then load and run the program, use the
following commands:

```
target remote | riscv32-gdbserver --stdin -c ri5cy
load
cont
```

You should see "Hello from RI5CY" in the output. Note that the hello world
example will only produce output on RI5CY, as the GDBServer does not support
hosted I/O for PicoRV32 at the current time.

A transcript of the whole GDB session follows:

```
$ riscv32-unknown-elf-gdb hello
GNU gdb (GDB) 8.0.50.20170519-git
Copyright (C) 2017 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "--host=x86_64-pc-linux-gnu --target=riscv32-unknown-elf".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<http://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
<http://www.gnu.org/software/gdb/documentation/>.
For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from hello...done.
(gdb) target remote | riscv32-gdbserver --stdin -c ri5cy
Remote debugging using | riscv32-gdbserver --stdin -c ri5cy
__ri5cy_reset_handler ()
    at /data/graham/projects/orconf/test/newlib/libgloss/riscv/ri5cy-interrupts.s:68
68              j __ri5cy_jump_to_start
(gdb) load
Loading section .interrupts, size 0x90 lma 0x0
Loading section .text, size 0x3044 lma 0x10094
Loading section .rodata, size 0x1c lma 0x130d8
Loading section .eh_frame, size 0x4 lma 0x130f4
Loading section .init_array, size 0x4 lma 0x140f8
Loading section .fini_array, size 0x4 lma 0x140fc
Loading section .data, size 0x830 lma 0x14100
Loading section .sdata, size 0x14 lma 0x14930
Start address 0x80, load size 14656
Transfer rate: 325 KB/sec, 212 bytes/write.
(gdb) cont
Continuing.
Hello from RI5CY

Program received signal SIGTRAP, Trace/breakpoint trap.
0x00012ed4 in __internal_syscall (n=93, _a1=0, _a2=0, _a3=0, _a0=_a0@entry=0)
    at /data/graham/projects/orconf/test/newlib/libgloss/riscv/machine/syscall.h:61
```

The `exit` implementation contains an EBREAK instruction, which traps and halts
GDB at this point.


Original README begins here: Embecosm RISC-V Toolchain
======================================================

This repository consists of scripts and related files for building and testing a
RISC-V tool chain. The main differences of this tool chain build from the RISC-V
Foundation's riscv-tools and riscv-gnu-toolchain builds are:

- This repository uses upstream Binutils and GCC. Once other components are
  merged upstream (e.g. GDB, Newlib...) are merged upstream, this repository
  will be updated to use the upstream versions of those components.
- Only Newlib builds are supported, for bare-metal systems. There is no Linux
  support at present.
- The default build is for RV32I. However, the architecture and ABI can be
modified.

Prerequisites
-------------

The Ri5cy and PivoRV32 verilator models require verilator version >=3.906.
Versions >=3.884 may also work but are untested.

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

Using a particular version of the source
----------------------------------------

The `checkout-tag.sh` script can be used to checkout a particular tag for each
repository

```
./checkout-all.sh  mytag
```

checks out the `mytag` tag on each branch.

Building the targets
--------------------

NOTE: verilator is required to build the PICOVR32 and RI5CY GDB Server

The tool chain and the targets are built separately. The targets
should be built first as the gdbserver needs to link against 
the generated PICORV32 and RI5CY verilator models.

To build the picorv32 and ri5cy verilator models:

```
./build-targets.sh
```

There are optional arguments `--ri5cy-source` and `picorv32-source`
which can be used to provide an alternative source directory to
for the respective targets. By default it is assumed that the
source is containing in `ri5cy` and `picorv32` directories in the
directory above the toolchain.

Building the tool chain
-----------------------

To build a 32-bit riscv32i tool chain (binutils, gdb, gcc, newlib, etc.):

```
./build-tools.sh
```

To see the options for `build-tools.sh`, use `./build-tools.sh --help`.
These include options for setting the architecture and ABI.

To build a 64-bit riscv64i tool chain, use:

```
./build-tools.sh --with-xlen 64 --with arch i --with-abi lp64
```

Building SPIKE
--------------

NOTE: The device-tree-compiler package is required to build riscv-isa-sim
(SPIKE).
NOTE: The tools should be built (eg by using the `build-tools.sh script),
before building the simulator.

To build spike for riscv32i :

```
./build-spike.sh
```

To see the options for `build-spike.sh`, use `./build-spike.sh --help`.
These include options for setting the target and architecture.

Building the ISA tests
----------------------

To build the ISA tests for the RISC-V

```
./build-isa-tests.sh
```

To see the options for `build-isa-tests.sh`, use
`./build-isa-tests.sh --help`.

Building testfloat
------------------

To build Berkeley TestFloat:

```
./build-testfloat.sh
```

To see the options for `build-testfloat.sh`, use `./build-testfloat.sh --help`.

Executing the GCC tests
-----------------------

To run with the GDB simulator:

```
./run-tests.sh
```

To run with the GDB Server for RI5CY:
```
./run-tests.sh --with-board riscv-ri5cy
```

To run with the GDB server for 64-bit RI5CY:
```
./run-tests.sh --with-board riscv-ri5cy --with-xlen 64
```

To run with the GDB Server for PICORV32:

```
./run-tests.sh --with-board riscv-picorv32
```

Executing the RISC-V ISA tests
------------------------------

The test must be built before running the tests. They can be built
using the `build-isa-tests.sh` script.

To run with the GDB Server for RI5CY:

```
./run-isa-tests.sh
```

Or

```
./run-isa-tests --with-board riscv-ri5cy
```

To run with the GDB Server for PICORV32:

```
./run-isa-tests --with-board riscv-picorv32
```

Tagging the tool chain
----------------------

There is a convenience script for developers, `tag-all.sh` which can be used
to tag the currently checked out points of every repository.  You must have
write access to the Embecosm organization for this to work.

```
tag-all.sh mytag "An example tag"
```

Will apply the `mytag` tag to all repositories, with the associated message
"An example tag".

