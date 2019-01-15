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

To build the RISC-V and ARM toolchains, use:

```
./build-riscv.sh
./build-arm.sh
```

There are arguments to these scripts, which can be viewed with the `--help`
option, but the default options are all appropriate for reproducing results
published from this repository.

Benchmarking
------------

Once the toolchains are built, the benchmarks can be run, with:

```
./benchmark-beebs.py
```

Results
-------

Presentation of results is a work-in-progress at present. In general the results
for each platform and configuration are held in the `testsuite/` subdir of each
BEEBS build.

To get a quick summary overview, one can run the following command (and see
similar output in the `build-riscv` subdir:

```
0 graham@pepper 00:34:45 /data/graham/projects/xyz/build-riscv
$ for i in beebs-*; do { echo $i; tail -n 100 $i/testsuite/beebs.log | grep Total; } done;
beebs-baseline
Total                 407681  27100  38510
beebs-nocrt
Total                 335661  12347  36287
beebs-nolibc
Total                 309762   6487  36119
beebs-nolibc-nolibgcc
Total                 193949   6487  36119
beebs-nolibc-nolibgcc-nolibm
Total                 182427   5863  36095
```

Similarly in the `build-arm` subdir:

```
0 graham@pepper 00:35:08 /data/graham/projects/xyz/build-arm
$ for i in beebs-*; do { echo $i; tail -n 100 $i/testsuite/beebs.log | grep Total; } done;
beebs-baseline
Total                 543278  47032  53064
beebs-nocrt
Total                 278586  11487  39375
beebs-nolibc
Total                 212825   5616  36111
beebs-nolibc-nolibgcc
Total                 170703   5616  36111
beebs-nolibc-nolibgcc-nolibm
Total                 160078   5614  36087
```

These results are obtained with the following revisions:

### BEEBS

```
commit 79bf5bcc271f992638a797c08a9a070cf1531186
Author: Graham Markall <graham.markall@embecosm.com>
Date:   Mon Jan 14 22:27:56 2019 +0000
```

### Binutils-GDB

```
commit d63f2be21bfbedb8a83b5c5f317896bf2bb19a95
Author: Rainer Orth <ro@CeBiTec.Uni-Bielefeld.DE>
Date:   Mon Jan 14 15:47:35 2019 +0100
```

### GCC

```
commit 0764f7c0c7ccc343793a21026eca1cd15af7e87c
Author: rguenth <rguenth@138bc75d-0d04-0410-961f-82ee72b054a4>
Date:   Mon Jan 14 13:11:43 2019 +0000
```

### Newlib

```
commit 19b7c7ab2e2fdfb70722bb016e67229c7184a173
Author: Corinna Vinschen <corinna@vinschen.de>
Date:   Sun Jan 13 23:35:28 2019 +0100
```

### RISCV-Toolchain

```
commit b41ef89c8a411c3b96ab063923f4b08d44e13b3a
Author: Graham Markall <graham.markall@embecosm.com>
Date:   Tue Jan 15 00:42:44 2019 +0000
```
