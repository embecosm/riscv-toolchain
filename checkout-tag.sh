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

#     checkout-all.sh <tag>

# Argument meanings:

#     <tag>  The tag to checkout

# Parse arg

if [ $# != 1 ]
then
    echo "Usage: checkout-tag.sh <tagname>"
    exit 1
fi

tagname=$1

# Set the top level directory.

topdir=$(cd $(dirname $0)/..;pwd)

# toolchain must be last repo!

repos="binutils      \
       gcc           \
       gdb           \
       newlib        \
       dejagnu       \
       gdbserver     \
       picorv32      \
       ri5cy         \
       riscv-pk      \
       riscv-fesvr   \
       riscv-isa-sim \
       beebs         \
       toolchain"

for r in ${repos}
do
    cd ${topdir}/${r}
    # Ignore failed fetches (may be offline)

    printf  "%-14s fetching..." "${r}:"
    echo fetch --all > /dev/null 2>&1 || true

    # Checkout the tag

    echo -n "checking out..."
    if ! git checkout ${tagname} > /dev/null 2>&1
    then
	echo "failed"
    else
	echo "succeeded"
    fi
done
