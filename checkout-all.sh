#!/bin/sh

# Checkout script for the RISC-V tool chain

# Copyright (C) 2009, 2013, 2014, 2015, 2016, 2017 Embecosm Limited
# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# This file is part of the Embecosm GNU toolchain build system for RISC-V.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.

# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.
# This file is part of the Embecosm LLVM build system for AAP.

# Invocation Syntax

#     checkout-all.sh [--pull]

# Argument meanings:

#     --pull  Pull the respositories as well as checking them out.

# Parse arg

if [ \( $# = 1 \) -a \( "x$1" = "x--pull" \) ]
then
    do_pull="yes"
else
    do_pull="no"
fi

# Set the top level directory.

topdir=$(cd $(dirname $0)/..;pwd)

repos="binutils:master                          \
       gcc:embecosm-stable                      \
       gdb:riscv-next                           \
       newlib:bare-metal-hack                   \
       dejagnu:riscv-dejagnu-1.6                \
       gdbserver:master                         \
       picorv32:gdbserver                       \
       ri5cy:verilator-model                    \
       riscv-pk:master                          \
       riscv-fesvr:master                       \
       riscv-isa-sim:master                     \
       beebs:picorv32                           \
       riscv-tests:master                       \
       berkeley-softfloat-3:master              \
       berkeley-testfloat-3:master"

for r in ${repos}
do
    tool=$(echo ${r} | cut -d ':' -f 1)
    branch=$(echo ${r} | cut -d ':' -f 2)

    cd ${topdir}/${tool}
    # Ignore failed fetches (may be offline)

    printf  "%-14s fetching...  " "${tool}:"
    git fetch --all > /dev/null 2>&1 || true

    # Checkout the branch. Not sure what happens if the branch is in mutliple
    # remotes.

    echo -n "checking out ${branch} ...  "
    git checkout ${branch} > /dev/null 2>&1 || true

    # Pull to the latest if requested.

    if [ ${do_pull} = "yes" ]
    then
	echo -n "pulling..."
	git pull > /dev/null 2>&1 || true
    fi

    # Repo done
    echo
done
