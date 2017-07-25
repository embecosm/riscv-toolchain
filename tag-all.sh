#!/bin/sh

# Tagging script for the RISC-V tool chain

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

#     tag-all.sh <tagname> <tagmess>

# Argument meanings:

#     <tagname>  Tag name to apply to all repositories

#     <tagmess>  Tag message to associate with the tag

# WARNING: It is up to the user to ensure all repositories are in the correct
# location that the remote is embecosm

# Parse args

if [ $# != 2 ]
then
    echo "Usage: tag-all.sh <tagname> <tagmess>"
    exit 1
fi

tagname=$1
tagmess="$2"

# Set the top level directory.

topdir=$(cd $(dirname $0)/..;pwd)

repos="binutils                 \
       gcc                      \
       gdb                      \
       newlib                   \
       dejagnu                  \
       gdbserver                \
       picorv32                 \
       ri5cy                    \
       riscv-pk                 \
       riscv-fesvr              \
       riscv-isa-sim            \
       beebs                    \
       riscv-tests              \
       berkely-softfloat-3      \
       berkely-testfloat-3      \
       toolchain"

for r in ${repos}
do
    cd ${topdir}/${r}

    printf  "%-14s tagging..." "${r}:"

    if git tag -a ${tagname} -m "${tagmess}" > /dev/null 2>&1 
    then
	# Tags are always on the embecosm remote.

	echo -n "pushing..."

	if ! git push embecosm ${tagname} > /dev/null 2>&1 
	then
	    echo "failed"
	else
	    echo "succeeded"
	fi
    else
	echo "failed"
    fi
done
