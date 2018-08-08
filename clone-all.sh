#!/bin/sh

# Clone script for the RISC-V tool chain

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

#		    SCRIPT TO CLONE THE RISC-V TOOL CHAIN
#		    =====================================

# Invocation Syntax

#     clone-all.sh [-dev]

# Argument meanings:

#     -dev  Clone Embecosm repos as SSH, rather than HTTPS, allowing write
#           access.

# If the BASE_URL environment variable is set, then that is used as the base of
# all repository URLs, to allow cloning from non-github sources (e.g. local
# mirrors).

# Set the top level directory.
topdir=$(cd $(dirname $0)/..;pwd)

cd ${topdir}

# get the most important ones first
git clone https://github.com/T-J-Teru/binutils-gdb.git binutils
ln -s binutils gdb
git clone https://github.com/gcc-mirror/gcc gcc
git clone --recursive https://github.com/riscv/riscv-openocd.git openocd

git clone https://github.com/embecosm/riscv-newlib.git newlib

# now get those for testing/executing
git clone https://github.com/T-J-Teru/dejagnu.git dejagnu

echo -e "\nNote: To build everything, you will need device-tree-compiler and verilator installed.\n"

