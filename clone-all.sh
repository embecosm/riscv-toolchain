#!/bin/sh

# Clone script for the RISC-V tool chain

# Copyright (C) 2009, 2013, 2014, 2015, 2016 Embecosm Limited
# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# This file is part of the Embecosm LLVM build system.

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

#		      SCRIPT TO CLONE AN LLVM TOOL CHAIN
#		      ==================================

# Invocation Syntax

#     clone-all.sh [-dev]


# Set the top level directory.
topdir=$(cd $(dirname $0)/..;pwd)

# Are we a developer?
if [ \( $# = 1 \) -a \( "x$1" = "x-dev" \) ]
then
    BASE_URL=git@github.com:embecosm
else
    BASE_URL=https://github.com/embecosm
fi

# Upstream repo name
US=github

cd ${topdir}
git clone -o ${US} git://sourceware.org/git/binutils-gdb.git binutils
git clone -o ${US} ssh://git@github.com/riscv/riscv-binutils-gdb gdb
git clone -o ${US} ssh://git@github.com/gcc-mirror/gcc gcc
git clone -o ${US} ssh://git@github.com/riscv/riscv-newlib.git newlib
git clone -o ${US} ssh://git@github.com/riscv/riscv-dejagnu.git dejagnu
