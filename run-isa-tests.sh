#!/bin/bash

error () {
    echo "ERROR: $1"
    exit 1
}

# ====================================================================

TOOLCHAIN_DIR=$(cd "`dirname \"$0\"`"; pwd)
TOP=$(cd ${TOOLCHAIN_DIR}/..; pwd)

# ====================================================================

BUILD_DIR=${TOP}/build
RESULTS_DIR=${TOP}/results
INSTALL_DIR=${TOP}/install

WITH_TARGET=riscv32-unknown-elf
TARGET_BOARD=riscv_ri5cy
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

    --comment)
	shift
	COMMENT=$1
	;;

    --help)
	echo "Usage: ./run-isa-tests.sh [--build-dir <dir>]"
	echo "                          [--install-dir <dir>]"
	echo "                          [--results-dir <dir>]"
	echo "                          [--with-target <target>]"
	echo "                          [--with-board <board>]"
	echo "                          [--comment <text>]"
	echo "                          [--help]"
	echo ""
	echo "The default --with-target is 'riscv32-unknown-elf'."
	echo ""
	echo "The default for --with-board is 'riscv-ri5cy', other"
	echo "option is 'riscv-picorv32'."
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

RESULTS_DIR=${RESULTS_DIR}/results-isa-tests-$(date +%F-%H%M)
mkdir -p ${RESULTS_DIR}
[ ! -z "${RESULTS_DIR}" ] || error "no results directory"
rm -f ${RESULTS_DIR}/*

# ====================================================================

RISCV_TESTS_BUILD_DIR=${BUILD_DIR}/riscv-tests

# ====================================================================

# To find riscv-gdbserver, runtest, etc.
PATH=${INSTALL_DIR}/bin:$PATH

# ====================================================================

# So that dejagnu can find the correct baseboard file
export DEJAGNULIB=${TOP}/dejagnu
export DEJAGNU=${TOOLCHAIN_DIR}/site.exp

# ====================================================================

# Start gdbserver, setting and exporting any board parameters
GDBSERVER_PID=
export RISCV_NETPORT=51235
export RISCV_TIMEOUT=10
export RISCV_GDB_TIMEOUT=10
export RISCV_STACK_SIZE="4096"
export RISCV_TEXT_SIZE="65536"

case "${TARGET_BOARD}" in
    riscv_picorv32)
	C_OPT="picorv32"
	;;
    riscv_ri5cy)
	C_OPT="RI5CY"
	;;
    *)
esac

ORIGINAL_TARGET_BOARD=${TARGET_BOARD}
TARGET_BOARD=riscv-gdbserver

echo ${INSTALL_DIR}/bin/riscv-gdbserver -c ${C_OPT} ${RISCV_NETPORT}
${INSTALL_DIR}/bin/riscv-gdbserver -c ${C_OPT} ${RISCV_NETPORT} & pid=$!
echo "Started GDB server on port ${RISCV_NETPORT} (process ${pid})"
GDBSERVER_PID=$pid

# ====================================================================

# Create a README with info about the test
readme=${RESULTS_DIR}/README
echo "Test of risc-v ISA conformance"                        >> ${readme}
echo "=============================="                        >> ${readme}
echo ""                                                      >> ${readme}
echo "Start time:         $(date -u +%d\ %b\ %Y\ at\ %H:%M)" >> ${readme}
echo "Target:             ${WITH_TARGET}"                    >> ${readme}
echo "Test board:         ${ORIGINAL_TARGET_BOARD}"          >> ${readme}
echo "Comment:            ${COMMENT}"                        >> ${readme}

# Run the tests
cd ${RISCV_TESTS_BUILD_DIR}

echo "runtest isa.exp --target_board=${TARGET_BOARD}"
runtest isa.exp --target_board=${TARGET_BOARD}

# 'testrun' is the default name as runtest was provided with no --tool arg
cp ${RISCV_TESTS_BUILD_DIR}/testrun.log ${RESULTS_DIR}/isa.log
cp ${RISCV_TESTS_BUILD_DIR}/testrun.sum ${RESULTS_DIR}/isa.sum

# ====================================================================

if [ ! -z "${GDBSERVER_PID}" ]
then
    echo "Killing off gdbserver (process ${GDBSERVER_PID})"
    kill -9 ${GDBSERVER_PID} &>/dev/null
fi

# ====================================================================
