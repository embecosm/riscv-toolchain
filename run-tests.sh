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
IGNORE_TESTS="--ignore 'store.exp advance.exp asmlabel.exp async.exp bp-permanent.exp break.exp condbreak-call-false.exp condbreak.exp consecutive-step-over.exp display.exp finish.exp funcargs.exp func-ptrs.exp longjmp.exp sepdebug.exp mi-var-cmd.exp mi-var-cp.exp dbx.exp dprintf.exp ena-dis-br.exp gnu_vector.exp hbreak2.exp label.exp macscp.exp recurse.exp return2.exp return.exp return-nodebug.exp scope.exp sss-bp-on-user-bp.exp stale-infcall.exp step-line.exp step-symless.exp step-test.exp until.exp vla-datatypes.exp vla-ptr.exp watchpoint-cond-gone.exp watchpoint.exp dw2-dir-file-name.exp dw2-skip-prologue.exp thread.exp mi-break.exp mi-nonstop-exit.exp mi-exit-code.exp mi-simplerun.exp mi-dprintf.exp mi-frame-regs.exp mi-var-display.exp inline-cmds.exp py-frame.exp py-framefilter.exp py-frame-inline.exp py-prettyprint.exp py-strfns.exp py-symbol.exp gdb11479.exp temargs.exp ovldbreak.exp chained-calls.exp method.exp classes.exp baseenum.exp breakpoint.exp shadow.exp filename.exp try_catch.exp mb-ctor.exp destrprint.exp expand-sals.exp extern-c.exp m-data.exp mb-inline.exp member-name.exp namespace.exp exception.exp nsnested.exp nsnoimports.exp ovsrch.exp pr-1210.exp pr17132.exp rtti.exp virtbase.exp virtfunc.exp skip-two.exp py-breakpoint.exp py-value.exp call-ar-st.exp call-sc.exp callfuncs.exp structs.exp'"

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
        echo "The default for --with-board is 'riscv-sim', other"
        echo "options are 'riscv-picorv32', 'riscv-ri5cy' or"
        echo "'riscv-freedom-e310-arty'."
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

[ ! -z "${RESULTS_DIR}" ] || error "no results directory"
mkdir -p "${RESULTS_DIR}" || error "failed to create results directory"
TMP_RESULTS_DIR=`mktemp -d -p ${RESULTS_DIR} "results-$(date +%F-%H%M)-XXXX" 2>/dev/null`
[ ! -z "${TMP_RESULTS_DIR}" ] || error "no run-specific results directory"
[ -d "${TMP_RESULTS_DIR}" ] || error "no run-specific results directory found"
rm -f ${TMP_RESULTS_DIR}/*
RESULTS_DIR=${TMP_RESULTS_DIR}

# ====================================================================

GCC_STAGE_2_BUILD_DIR=${BUILD_DIR}/gcc-stage2
GDB_BUILD_DIR=${BUILD_DIR}/gdb

# ====================================================================

# So that spike, riscv32-unknown-elf-run, etc. can be found
export PATH=${INSTALL_DIR}/bin:$PATH

# ====================================================================

# So that dejagnu can find the correct baseboard file (e.g. riscv-spike.exp)
export DEJAGNULIBS=${TOP}/dejagnu
export DEJAGNU=${TOOLCHAIN_DIR}/site.exp
export DEJAGNU_LDSCRIPT=
export DEJAGNU_BSP=${TOOLCHAIN_DIR}/bsp
# ====================================================================

# Start gdbserver
GDBSERVER_PID=

case "${TARGET_BOARD}" in
    riscv-picorv32|riscv-ri5cy)
	# Set up and export any board parameters.
	export RISCV_NETPORT=51235

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

if [ "${TARGET_BOARD}" = "riscv-freedom-e310-arty" ]
then
    export RISCV_NETPORT=3333
    export DEJAGNU_LDSCRIPT=-T${TOOLCHAIN_DIR}/boardsupport/freedom-e300-arty/flash.lds
    export DEJAGNU_OPENOCD=${INSTALL_DIR}/bin/openocd
    export DEJAGNU_OPENOCD_CFG=${TOOLCHAIN_DIR}/bsp/env/freedom-e300-arty/openocd.cfg
    export DEJAGNU_OPENOCD_LOG=${RESULTS_DIR}/openocd.log

    # We only start one gdbserver, so only run one test at a time.
    PARALLEL=1
fi

TARGET_XLEN=
case "${WITH_TARGET}" in
    riscv32-unknown-elf|riscv32imac-unknown-elf)
        TARGET_XLEN=32
        ;;
    riscv64-unknown-elf)
        TARGET_XLEN=64
        ;;
esac

if [ -z "${TARGET_XLEN}" ]
then
    echo "Couldn't figure out XLEN value"
    exit 1
fi

export RISCV_TIMEOUT=10
export RISCV_GDB_TIMEOUT=10
export RISCV_STACK_SIZE="2048"
export RISCV_TEXT_SIZE="65535"
export RISCV_XLEN=${TARGET_XLEN}

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
    make -j $PARALLEL check-gcc-c RUNTESTFLAGS="${TEST_SUBSET} --target=${WITH_TARGET} --target_board=${TARGET_BOARD} ${IGNORE_TESTS}"
	cp ${GCC_STAGE_2_BUILD_DIR}/gcc/testsuite/gcc/gcc.log ${RESULTS_DIR}/gcc.log
	cp ${GCC_STAGE_2_BUILD_DIR}/gcc/testsuite/gcc/gcc.sum ${RESULTS_DIR}/gcc.sum
        ;;
    gdb)
    cd ${GDB_BUILD_DIR}
    make -j $PARALLEL check-gdb RUNTESTFLAGS="${TEST_SUBSET} --target=${WITH_TARGET} --target_board=${TARGET_BOARD} ${IGNORE_TESTS}"
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
