#!/bin/bash

error () {
    echo "ERROR: $1"
    exit 1
}

# ====================================================================

TOOLCHAIN_DIR=$(cd "`dirname \"$0\"`"; pwd)
TOP=$(cd ${TOOLCHAIN_DIR}/..; pwd)

# ====================================================================

WITH_TARGET=riscv32-unknown-elf
BUILD_DIR=${TOP}/build
RESULTS_DIR=${TOP}/results
INSTALL_DIR=${TOP}/install
TARGET_BOARD=riscv-sim
TARGET_SUBSET=
TOOL=gcc
COMMENT="none"

# ====================================================================

until
opt=$1
case ${opt} in
    --build-dir)
	shift
	BUILD_DIR=$(realpath -m $1)
	;;

    --install-dir)
	shift
	INSTALL_DIR=$(realpath -m $1)
	;;

    --results-dir)
	shift
	RESULTS_DIR=$(realpath -m $1)
	;;

    --jobs)
	shift
	JOBS=$1
	;;

    --load)
	shift
	LOAD=$1
	;;

    --with-target)
	shift
	WITH_TARGET=$1
	;;

    --with-board)
	shift
	TARGET_BOARD=$1
	;;

    --test-subset)
	shift
	TEST_SUBSET=$1
	;;

    --tool)
	shift
	TOOL=$1
	;;

    --comment)
	shift
	COMMENT=$1
	;;

    --help)
	echo "Usage: ./run-tests.sh [--build-dir <dir>]"
	echo "                      [--install-dir <dir>]"
	echo "                      [--results-dir <dir>]"
	echo "                      [--jobs <count>] [--load <load>]"
	echo "                      [--with-target <triplet>]"
	echo "                      [--with-board <board>]"
	echo "                      [--test-subset <string>]"
	echo "                      [--tool gcc | gdb]"
	echo "                      [--comment <text>]"
	echo "                      [--help]"
	echo ""
	echo "The default --with-target is 'riscv32-unknown-elf'."
	echo ""
	echo "The default for --with-board is 'riscv-sim', other"
	echo "options are 'riscv-picorv32' or 'riscv-ri5cy'."
	echo ""
	exit 1
	;;

    ?*)
	error "Unknown argument '$1' (try --help)"
	;;

    *)
	;;
esac
[ "x${opt}" = "x" ]
do
    shift
done

# ====================================================================

RESULTS_DIR=${RESULTS_DIR}/results-$(date +%F-%H%M)
mkdir -p ${RESULTS_DIR}
[ ! -z "${RESULTS_DIR}" ] || error "no results directory"
rm -f ${RESULTS_DIR}/*

# ====================================================================

GCC_STAGE_2_BUILD_DIR=${BUILD_DIR}/gcc-stage-2
GDB_BUILD_DIR=${BUILD_DIR}/gdb

# ====================================================================

# So that spike, riscv32-unknown-elf-run, etc. can be found
export PATH=${INSTALL_DIR}/bin:$PATH

# ====================================================================

# So that dejagnu can find the correct baseboard file (e.g. riscv-spike.exp)
export DEJAGNULIBS=${TOP}/dejagnu
export DEJAGNU=${TOOLCHAIN_DIR}/site.exp

# ====================================================================

# Default parallelism
processor_count="`(echo processor; cat /proc/cpuinfo 2>/dev/null echo processor) \
           | grep -c processor`"
if [ "x${JOBS}" == "x" ]; then JOBS=${processor_count}; fi
if [ "x${LOAD}" == "x" ]; then LOAD=${processor_count}; fi
PARALLEL="-j ${JOBS} -l ${LOAD}"

case "${TARGET_BOARD}" in
    riscv-picorv32|riscv-ri5cy)
	# Set up and export board parameters
	export RISCV_TIMEOUT=10
	export RISCV_GDB_TIMEOUT=10
	export RISCV_STACK_SIZE="4096"
	export RISCV_TEXT_SIZE="65536"

	if [ "${TARGET_BOARD}" == "riscv-ri5cy" ]; then
	    export RISCV_CORE=ri5cy
	elif [ "${TARGET_BOARD}" == "riscv-picorv32" ]; then
	    export RISCV_CORE=picorv32
	fi
	TARGET_BOARD=riscv-gdbserver
	;;
    *)
	;;
esac

# ====================================================================

# Create a README with info about the test
readme=${RESULTS_DIR}/README
echo "Test of risc-v tool chain"                       >  ${readme}
echo "========================="                       >> ${readme}
echo ""                                                >> ${readme}
echo "Start time:   $(date -u +%d\ %b\ %Y\ at\ %H:%M)" >> ${readme}
echo "Parallel:     ${PARALLEL}"                       >> ${readme}
echo "Target:       ${WITH_TARGET}"                    >> ${readme}
echo "Test board:   ${ORIGINAL_TARGET_BOARD}"          >> ${readme}
echo "Test subset:  ${TEST_SUBSET}"                    >> ${readme}
echo "Comment:      ${COMMENT}"                        >> ${readme}
echo "Tool:         ${TOOL}"                           >> ${readme}

case "${TOOL}" in
    gcc)
	cd ${GCC_STAGE_2_BUILD_DIR}
	make $PARALLEL check-gcc-c RUNTESTFLAGS="${TEST_SUBSET} --target=${WITH_TARGET} --target_board=${TARGET_BOARD}"
	cp ${GCC_STAGE_2_BUILD_DIR}/gcc/testsuite/gcc/gcc.log ${RESULTS_DIR}/gcc.log
	cp ${GCC_STAGE_2_BUILD_DIR}/gcc/testsuite/gcc/gcc.sum ${RESULTS_DIR}/gcc.sum
	;;
    gdb)
	cd ${GDB_BUILD_DIR}
	make $PARALLEL check-gdb RUNTESTFLAGS="${TEST_SUBSET} --target=${WITH_TARGET} --target_board=${TARGET_BOARD}"
	cp ${GDB_BUILD_DIR}/gdb/testsuite/gdb.log ${RESULTS_DIR}/gdb.log
	cp ${GDB_BUILD_DIR}/gdb/testsuite/gdb.sum ${RESULTS_DIR}/gdb.sum
	;;
    *)
	error "unknown tool ${TOOL}"
	;;
esac

# ====================================================================
