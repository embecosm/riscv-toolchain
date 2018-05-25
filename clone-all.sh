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

# Are we a developer?
if [ \( $# = 1 \) -a \( "x$1" = "x-dev" \) ]
then
    BASE_URL=git@github.com:embecosm
fi

# Set the default base URL, if it is not already provided by the environment.
if [ -z ${BASE_URL+x} ]
then
    BASE_URL=https://github.com/embecosm
fi

# Upstream repo names
US=github
EM=embecosm

cd ${topdir}

# get the most important ones first
git clone -o ${EM} ${BASE_URL}/riscv-binutils-gdb.git binutils
git clone -o ${EM} ${BASE_URL}/riscv-gcc.git gcc
git clone -o ${EM} ${BASE_URL}/riscv-gdb.git gdb
git clone -o ${EM} ${BASE_URL}/riscv-newlib.git newlib

# now get cgen
git clone -o ${EM} ${BASE_URL}/cgen.git cgen

# now get those for testing/executing
git clone -o ${EM} ${BASE_URL}/riscv-gdbserver.git gdbserver
git clone -o ${EM} ${BASE_URL}/picorv32.git picorv32
git clone -o ${EM} ${BASE_URL}/ri5cy.git ri5cy
#git clone -o ${EM} ${BASE_URL}/riscv-pk.git riscv-pk
#git clone -o ${EM} ${BASE_URL}/riscv-fesvr.git riscv-fesvr
git clone -o ${EM} ${BASE_URL}/riscv-isa-sim.git riscv-isa-sim

#git clone -o ${EM} ${BASE_URL}/riscv-tests.git riscv-tests

# initialize the submodule for the test environment in riscv-tests
cd riscv-tests
git submodule update --init --recursive
cd ${topdir}

echo -e "\nNote: To build everything, you will need device-tree-compiler and verilator installed.\n"

