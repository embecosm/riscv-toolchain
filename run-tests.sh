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
BUILD_DIR=${TOP}/build-riscv
RESULTS_DIR=${TOP}/logs
INSTALL_DIR=${TOP}/install-riscv
TARGET_BOARD=riscv-sim
TARGET_SUBSET=
TOOL=gcc
COMMENT="none"

GCC_BUILD_DIR=${BUILD_DIR}/gcc-stage-2

# Default parallellism
processor_count="`(echo processor; cat /proc/cpuinfo 2>/dev/null echo processor) \
           | grep -c processor`"
if [ -z "${JOBS}" ]; then JOBS=${processor_count}; fi
if [ -z "${LOAD}" ]; then LOAD=${processor_count}; fi
PARALLEL="-j ${JOBS} -l ${LOAD}"


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

    --with-target)
        shift
        case $1 in
          riscv*)
            WITH_TARGET=$1
            ;;
          x86_64-pc-linux-gnu)
            WITH_TARGET=$1
            TARGET_BOARD=""
            GCC_BUILD_DIR="${BUILD_DIR}/gcc-native"
            ;;
        esac
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

GDB_BUILD_DIR=${BUILD_DIR}/gdb

# ====================================================================

# Add tools to path
export PATH=${INSTALL_DIR}/bin:$PATH

# ====================================================================

# So that dejagnu can find the correct baseboard file (e.g. riscv-sim.exp)
export DEJAGNU=${TOOLCHAIN_DIR}/site.exp

# ====================================================================


# Create a README with info about the test
readme=${RESULTS_DIR}/README
echo "Test of risc-v tool chain"                             >  ${readme}
echo "========================="                             >> ${readme}
echo ""                                                      >> ${readme}
echo "Start time:         $(date -u +%d\ %b\ %Y\ at\ %H:%M)" >> ${readme}
echo "Target:             ${WITH_TARGET}"                    >> ${readme}
echo "Board:              ${TARGET_BOARD}"                   >> ${readme}
echo "Test subset:        ${TEST_SUBSET}"                    >> ${readme}
echo "Comment:            ${COMMENT}"                        >> ${readme}
echo "Tool:               ${TOOL}"                           >> ${readme}

case "${WITH_TARGET}" in
  riscv*)
    RUNTESTFLAGS="${TEST_SUBSET} --target=${WITH_TARGET} --target_board=${TARGET_BOARD}"
    ;;
  *)
    RUNTESTFLAGS="${TEST_SUBSET}"
    ;;
esac

case "${TOOL}" in
    gcc)
        cd ${GCC_BUILD_DIR}
        make $PARALLEL check-gcc-c RUNTESTFLAGS="${RUNTESTFLAGS}"
	cp ${GCC_BUILD_DIR}/gcc/testsuite/gcc/gcc.log ${RESULTS_DIR}/gcc.log
	cp ${GCC_BUILD_DIR}/gcc/testsuite/gcc/gcc.sum ${RESULTS_DIR}/gcc.sum
        ;;
    g++)
        cd ${GCC_BUILD_DIR}
        make $PARALLEL check-gcc-c++ RUNTESTFLAGS="${RUNTESTFLAGS}"
	cp ${GCC_BUILD_DIR}/gcc/testsuite/g++/g++.log ${RESULTS_DIR}/g++.log
	cp ${GCC_BUILD_DIR}/gcc/testsuite/g++/g++.sum ${RESULTS_DIR}/g++.sum
        ;;
    libstdc++)
        cd ${GCC_BUILD_DIR}
        make $PARALLEL check-target-libstdc++-v3 RUNTESTFLAGS="${RUNTESTFLAGS}"
	cp ${GCC_BUILD_DIR}/${WITH_TARGET}/libstdc++-v3/testsuite/libstdc++.log ${RESULTS_DIR}/libstdc++.log
	cp ${GCC_BUILD_DIR}/${WITH_TARGET}/libstdc++-v3/testsuite/libstdc++.sum ${RESULTS_DIR}/libstdc++.sum
        ;;
    gdb)
        cd ${GDB_BUILD_DIR}
        make $PARALLEL check-gdb RUNTESTFLAGS="${RUNTESTFLAGS}"
	cp ${GDB_BUILD_DIR}/gdb/testsuite/gdb.log ${RESULTS_DIR}/gdb.log
	cp ${GDB_BUILD_DIR}/gdb/testsuite/gdb.sum ${RESULTS_DIR}/gdb.sum
        ;;
    *)
        error "unknown tool ${TOOL}"
        ;;
esac

# ====================================================================
