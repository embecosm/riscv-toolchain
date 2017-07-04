#!/bin/bash

# Simple script for running GCC regression tests for the RISC-V toolchain

# Copyright (C) 2017 Embecosm Limited.
# Contributor Ian Bolton <ian.bolton@embecosm.com>

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
#
#
# Example invocations:
#
#   ./run-tests.sh
#   TARGET_BOARD=riscv-sim TARGET_TRIPLET=riscv64-unknown-elf ./run-tests.sh
#   RESULTS_DIR=`pwd` ./run-tests.sh
#


### DECIDE WHERE KEY THINGS ARE ###

# Set up various directory variables
TOOLCHAIN_DIR=$(cd "`dirname \"$0\"`"; pwd)
TOP=$(cd ${TOOLCHAIN_DIR}/..; pwd)
INSTALL_DIR=${TOP}/install
BUILD_DIR=${TOP}/build
GCC_STAGE_2_BUILD_DIR=${BUILD_DIR}/gcc-stage-2

# So that spike, riscv32-unknown-elf-run, etc. can be found
export PATH=${INSTALL_DIR}/bin:$PATH

# So that dejagnu can find the correct baseboard file (e.g. riscv-spike.exp)
export DEJAGNULIBS=${TOP}/dejagnu
export DEJAGNU=${TOOLCHAIN_DIR}/site.exp


### RESPOND TO ENVIRONMENT VARIABLES ###

# For simplicity, we allow the user to select the board via environment variable
#   e.g. TARGET_BOARD=riscv-sim ./run-tests.sh
if test x"$TARGET_BOARD" = x
then
	# Using SPIKE is the default because it passes more tests
	TARGET_BOARD="riscv-spike"
fi


# As with TARGET_BOARD, this is selectable via environment variable, for simplicity
#   e.g. TARGET_TRIPLET=riscv64-unknown-elf ./run-tests.sh
if test x"$TARGET_TRIPLET" = x
then
	# Our default architecture of interest is 32-bit
	TARGET_TRIPLET=riscv32-unknown-elf
fi


# Optionally define this to refer to specific tests
#   e.g. TEST_SUBSET="execute.exp=2010*"
if test x"$TEST_SUBSET" = x
then
	# The default is blank, to run everything
	TEST_SUBSET=
fi



### DO THE ACTUAL WORK ###

# Needs to be run in the build tree for gcc
cd ${GCC_STAGE_2_BUILD_DIR}

if test x"$TARGET_BOARD" = xriscv-picorv32
then
	# Set up and export any board parameters
	export RISCV_NETPORT=51235
	export RISCV_TIMEOUT=10
	export RISCV_GDB_TIMEOUT=10
	export RISCV_STACK_SIZE="4096"
	export RISCV_TEXT_SIZE="65536"

	# invoking one gdbserver
	PARALLEL=1
	echo "Launching GDB Server on port ${RISCV_NETPORT}"
	${INSTALL_DIR}/bin/riscv-gdbserver -c picorv32 ${RISCV_NETPORT} &
	TARGET_BOARD=riscv-gdbserver
else
if test x"$TARGET_BOARD" = xriscv-ri5cy
then
	# Set up and export any board parameters
	export RISCV_NETPORT=51235
	export RISCV_TIMEOUT=10
	export RISCV_GDB_TIMEOUT=10
	export RISCV_STACK_SIZE="4096"
	export RISCV_TEXT_SIZE="65536"

	# invoking one gdbserver
	PARALLEL=1
	echo "Launching GDB Server on port ${RISCV_NETPORT}"
	${INSTALL_DIR}/bin/riscv-gdbserver -c RI5CY ${RISCV_NETPORT} &
	TARGET_BOARD=riscv-gdbserver
else
	PARALLEL=8
fi
fi


# We use check-gcc-c by default, so that no c++ tests are run
make -j $PARALLEL check-gcc-c RUNTESTFLAGS="${TEST_SUBSET} --target=${TARGET_TRIPLET} --target_board=${TARGET_BOARD}"



### FINISH UP ###

# Print out where the results are, so user can easily refer to them
echo "--------------------------------------------------------------------"
echo "RESULTS FILES (which will be overwritten if you run again) ARE HERE:" 
echo "Complete log: ${GCC_STAGE_2_BUILD_DIR}/gcc/testsuite/gcc/gcc.log"
echo "Summary file: ${GCC_STAGE_2_BUILD_DIR}/gcc/testsuite/gcc/gcc.sum"


# Kill off riscv-gdbserver
echo "Killing off all riscv-gdbserver processes."
killall -9 riscv-gdbserver

# Make it easy for the user to back-up their results, if they supplied a RESULTS_DIR
if test x"$RESULTS_DIR" != x
then
if [ -d $RESULTS_DIR ]
then
	# If the directory exists, copy logs there for convenience
	echo "Results were also copied to here:"
	FINISHED=$(date +%Y%m%d%H%M%S)
	DIFFERENTIATOR=${TARGET_TRIPLET}.${TARGET_BOARD}.${FINISHED}
	echo "Complete log: ${RESULTS_DIR}/gcc.${DIFFERENTIATOR}.log"
	echo "Summary file: ${RESULTS_DIR}/gcc.${DIFFERENTIATOR}.sum"
	cp ${GCC_STAGE_2_BUILD_DIR}/gcc/testsuite/gcc/gcc.log ${RESULTS_DIR}/gcc.${DIFFERENTIATOR}.log
	cp ${GCC_STAGE_2_BUILD_DIR}/gcc/testsuite/gcc/gcc.sum ${RESULTS_DIR}/gcc.${DIFFERENTIATOR}.sum
else
	# Keep things simple, rather than create new directories based on an environment variable
	echo "(Results were not copied to $RESULTS_DIR because it doesn't exist.)"
fi
fi
