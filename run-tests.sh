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
TARGET_BOARD=riscv-spike
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
        echo "                      [--with-target <triplet>]"
        echo "                      [--with-board <board>]"
        echo "                      [--test-subset <string>]"
        echo "                      [--tool gcc | gdb]"
        echo "                      [--comment <text>]"
        echo "                      [--help]"
        echo ""
        echo "The default --with-target is 'riscv32-unknown-elf'."
        echo ""
        echo "The default for --with-board is 'riscv-spike', other"
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

# Start gdbserver
GDBSERVER_PID=
case "${TARGET_BOARD}" in
    riscv-picorv32|riscv-ri5cy)
	# Set up and export any board parameters.
	export RISCV_NETPORT=51235
	export RISCV_TIMEOUT=10
	export RISCV_GDB_TIMEOUT=10
	export RISCV_STACK_SIZE="4096"
	export RISCV_TEXT_SIZE="65536"

	# We only start one gdbserver, so only run one test at a time.
	PARALLEL=1

        # Select the -c option to pass when starting gdbserver.
        case "${TARGET_BOARD}" in
            riscv-picorv32)
                C_OPT="picorv32"
                ;;
            riscv-ri5cy)
                C_OPT="RI5CY"
                ;;
            *)
        esac

        # Select common board name to select the dejagnu config file.
        ORIGINAL_TARGET_BOARD=${TARGET_BOARD}
        TARGET_BOARD=riscv-gdbserver

        echo ${INSTALL_DIR}/bin/riscv-gdbserver -c ${C_OPT} ${RISCV_NETPORT}
        ${INSTALL_DIR}/bin/riscv-gdbserver -c ${C_OPT} ${RISCV_NETPORT} & pid=$!
	echo "Started GDB server on port ${RISCV_NETPORT} (process ${pid})"
        GDBSERVER_PID=$pid
        ;;

    *)
	PARALLEL=8
        ;;
esac

# ====================================================================

# Create a README with info about the test
readme=${RESULTS_DIR}/README
echo "Test of risc-v tool chain"                             >  ${readme}
echo "========================="                             >> ${readme}
echo ""                                                      >> ${readme}
echo "Start time:         $(date -u +%d\ %b\ %Y\ at\ %H:%M)" >> ${readme}
echo "Target:             ${WITH_TARGET}"                    >> ${readme}
echo "Test board:         ${ORIGINAL_TARGET_BOARD}"          >> ${readme}
echo "Test subset:        ${TEST_SUBSET}"                    >> ${readme}
echo "Comment:            ${COMMENT}"                        >> ${readme}
echo "Tool:               ${TOOL}"                           >> ${readme}

case "${TOOL}" in
    gcc)
        cd ${GCC_STAGE_2_BUILD_DIR}
        make -j $PARALLEL check-gcc-c RUNTESTFLAGS="${TEST_SUBSET} --target=${WITH_TARGET} --target_board=${TARGET_BOARD}"
	cp ${GCC_STAGE_2_BUILD_DIR}/gcc/testsuite/gcc/gcc.log ${RESULTS_DIR}/gcc.log
	cp ${GCC_STAGE_2_BUILD_DIR}/gcc/testsuite/gcc/gcc.sum ${RESULTS_DIR}/gcc.sum
        ;;
    gdb)
        cd ${GDB_BUILD_DIR}
        make -j $PARALLEL check-gdb RUNTESTFLAGS="${TEST_SUBSET} --target=${WITH_TARGET} --target_board=${TARGET_BOARD}"
	cp ${GDB_BUILD_DIR}/gdb/testsuite/gdb.log ${RESULTS_DIR}/gdb.log
	cp ${GDB_BUILD_DIR}/gdb/testsuite/gdb.sum ${RESULTS_DIR}/gdb.sum
        ;;
    *)
        error "unknown tool ${TOOL}"
        ;;
esac

# ====================================================================

if [ ! -z "${GDBSERVER_PID}" ]
then
    echo "Killing off gdbserver (process ${GDBSERVER_PID})"
    kill -9 ${GDBSERVER_PID} &>/dev/null
fi

# ====================================================================
