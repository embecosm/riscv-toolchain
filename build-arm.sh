#!/bin/bash

TOOLCHAIN_DIR=$(cd "`dirname \"$0\"`"; pwd)
TOP=$(cd ${TOOLCHAIN_DIR}/..; pwd)

# ====================================================================

CLEAN_BUILD=no
DEBUG_BUILD=no
BUILD_DIR=${TOP}/build-arm
INSTALL_DIR=${TOP}/install-arm

# ====================================================================

# These are deliberately left blank, defaults are filled in below as
# appropriate.

WITH_XLEN=
WITH_ARCH=
WITH_ABI=
WITH_FPU=
JOBS=
LOAD=

# ====================================================================

function usage () {
    MSG=$1

    echo "${MSG}"
    echo
    echo "Usage: ./build-tools.sh [--build-dir <build_dir>]"
    echo "                        [--install-dir <install_dir>]"
    echo "                        [--jobs <count>] [--load <load>]"
    echo "                        [--single-thread]"
    echo "                        [--clean]"
    echo "                        [--debug]"
    echo "                        [--with-xlen <xlen>]"
    echo "                        [--with-target <target>]"
    echo "                        [--with-arch <arch>]"
    echo "                        [--with-abi <abi>]"
    echo
    echo "--with-xlen:"
    echo "        Choose between 32 or 64.  Default is 32."
    echo ""
    echo "--with-target:"
    echo "        Defaults are arm-none-eabi or aarch64-none-elf"
    echo "        depending on the value of --with-xlen. Possibly"
    echo "        armv8l-none-eabi might work as well."
    echo ""
    echo "--with-cpu:"
    echo "        Defaults are cortex-m4 or cortex-a53  depending on the value"
    echo "        of --with-xlen."
    echo ""
    echo "--with-fpu:"
    echo "        Can only be used with --with-xlen is 32."
    echo ""
    echo "--with-float:"
    echo "        Defaults to hard if --with-fpu is specified or if the value"
    echo "        of --with-xlen is 64 and soft otherwise."
    echo ""
    echo "--with-mode:"
    echo "        Defaults to thumb"

    exit 1
}

XLEN_SPECIFIED=no
TARGET_SPECIFIED=no
CPU_SPECIFIED=no
FPU_SPECIFIED=no
FLOAT_SPECIFIED=no
MODE_SPECIFIED=no

# Parse options
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

    --jobs)
	shift
	JOBS=$1
	;;

    --load)
	shift
	LOAD=$1
	;;

    --single-thread)
	JOBS=1
	LOAD=1000
	;;

    --clean)
	CLEAN_BUILD=yes
	;;

    --debug)
	DEBUG_BUILD=yes
	;;

    --with-xlen)
	shift
	WITH_XLEN=$1
        XLEN_SPECIFIED=yes
	;;

    --with-target)
	shift
	TARGET_TRIPLET=$1
        TARGET_SPECIFIED=yes
	;;

    --with-cpu)
	shift
	WITH_CPU=$1
        CPU_SPECIFIED=yes
	;;

    --with-fpu)
	shift
	WITH_FPU=$1
        FPU_SPECIFIED=yes
	;;

    --with-float)
	shift
	WITH_FLOAT=$1
        FLOAT_SPECIFIED=yes
	;;

    --with-mode)
	shift
	WITH_MODE=$1
        MODE_SPECIFIED=yes
	;;

    ?*)
	usage "Unknown argument $1"
	;;

    *)
	;;
esac
[ "x${opt}" = "x" ]
do
    shift
done

set -u

# ====================================================================
# Select suitable defaults based on the value of --with-xlen

if [ "${XLEN_SPECIFIED}" == "no" ]
then
    WITH_XLEN=32
fi

if [ "${TARGET_SPECIFIED}" == "no" ]
then
    case ${WITH_XLEN} in
	32)
	    TARGET_TRIPLET=arm-none-eabi
	    ;;
	64)
	    TARGET_TRIPLET=aarch64-none-elf
	    ;;
    esac
fi

if [ "${CPU_SPECIFIED}" = "no" ]
then
    case ${WITH_XLEN} in
	32)
	    WITH_CPU=cortex-m4
	    ;;
	64)
	    WITH_CPU=cortex-a53
	    ;;
    esac
fi

if [ "${WITH_XLEN}" = "32" ]
then
    if [ "${FPU_SPECIFIED}" = "yes" ]
    then
        WITH_FPU_STRING="--with-fpu=${WITH_FPU}"
    else
        WITH_FPU_STRING=""
    fi
else
    if [ "${FPU_SPECIFIED}" = "yes" ]
    then
	echo "Warning: --with-cpu ignored for AArch 64"
	WITH_FPU=""
	WITH_FPU_STRING=""
    fi
fi

if [ "${FLOAT_SPECIFIED}" = "no" ]
then
    case ${WITH_XLEN} in
	32)
	    if [ ${FPU_SPECIFIED} = "yes" ]
	    then
		WITH_FLOAT="hard"
	    else
		WITH_FLOAT="soft"
	    fi
	    ;;
	64)
	    WITH_FLOAT="hard"
	    ;;
    esac
fi

if [ "${MODE_SPECIFIED}" = "no" ]
then
    WITH_MODE="thumb"
fi

TARGET_GCC_CONFIG_FLAGS="--with-cpu=${WITH_CPU} ${WITH_FPU_STRING} --with-float=${WITH_FLOAT} --with-mode=${WITH_MODE}"
QEMU_TARGETS="arm-softmmu,arm-linux-user"
QEMU_SCRIPTS="arm-none-eabi-run"

# ====================================================================

echo "               Top: ${TOP}"
echo "         Toolchain: ${TOOLCHAIN_DIR}"
echo "              Xlen: ${WITH_XLEN}"
echo "            Target: ${TARGET_TRIPLET}"
echo "               CPU: ${WITH_CPU}"
echo "               FPU: ${WITH_FPU}"
echo "             FLOAT: ${WITH_FLOAT}"
echo "              MODE: ${WITH_MODE}"
echo "       Debug build: ${DEBUG_BUILD}"
echo "         Build Dir: ${BUILD_DIR}"
echo "       Install Dir: ${INSTALL_DIR}"

if [ "x${CLEAN_BUILD}" = "xyes" ]
then
    for T in `seq 5 -1 1`
    do
	echo -ne "\rClean Build: yes (in ${T} seconds)"
	sleep 1
    done
    echo -e "\rClean Build: yes                           "
    rm -fr ${BUILD_DIR} ${INSTALL_DIR}
else
    echo "Clean Build: no"
fi

if [ "x${DEBUG_BUILD}" = "xyes" ]
then
    export CFLAGS="-g3 -O0"
    export CXXFLAGS="-g3 -O0"
fi

BINUTILS_BUILD_DIR=${BUILD_DIR}/binutils-gdb
GCC_STAGE_1_BUILD_DIR=${BUILD_DIR}/gcc-stage-1
GCC_STAGE_2_BUILD_DIR=${BUILD_DIR}/gcc-stage-2
GCC_NATIVE_BUILD_DIR=${BUILD_DIR}/gcc-native
NEWLIB_BUILD_DIR=${BUILD_DIR}/newlib
QEMU_BUILD_DIR=${BUILD_DIR}/qemu

INSTALL_PREFIX_DIR=${INSTALL_DIR}
INSTALL_SYSCONF_DIR=${INSTALL_DIR}/etc
INSTALL_LOCALSTATE_DIR=${INSTALL_DIR}/var

SYSROOT_DIR=${INSTALL_DIR}/${TARGET_TRIPLET}/sysroot
SYSROOT_HEADER_DIR=${SYSROOT_DIR}/usr

# Default parallellism
processor_count="`(echo processor; cat /proc/cpuinfo 2>/dev/null echo processor) \
           | grep -c processor`"
if [ -z "${JOBS}" ]; then JOBS=${processor_count}; fi
if [ -z "${LOAD}" ]; then LOAD=${processor_count}; fi
PARALLEL="-j ${JOBS} -l ${LOAD}"

JOB_START_TIME=
JOB_TITLE=

SCRIPT_START_TIME=`date +%s`

LOGDIR=${TOP}/logs
LOGFILE=${LOGDIR}/build-$(date +%F-%H%M).log

echo "   Log file: ${LOGFILE}"
echo "   Start at: "`date`
echo "   Parallel: ${PARALLEL}"
echo ""

rm -f ${LOGFILE}
if ! mkdir -p ${LOGDIR}
then
    echo "Failed to create log directory: ${LOGDIR}"
    exit 1
fi

if ! touch ${LOGFILE}
then
    echo "Failed to initialise logfile: ${LOGFILE}"
    exit 1
fi

# ====================================================================

# Defines: msg, error, times_to_time_string, job_start, job_done,
#          mkdir_and_enter, enter_dir, run_command
#
# Requires LOGFILE and SCRIPT_START_TIME environment variables to be
# set.
source common.sh

# ====================================================================
#                    Locations of all the source
# ====================================================================

export BINUTILS_GDB_SOURCE_DIR=${TOP}/binutils-gdb
export GCC_SOURCE_DIR=${TOP}/gcc
export NEWLIB_SOURCE_DIR=${TOP}/newlib
export QEMU_SOURCE_DIR=${TOP}/qemu
export BEEBS_SOURCE_DIR=${TOP}/beebs

# ====================================================================
#                Log git versions into the build log
# ====================================================================

job_start "Writing git versions to log file"
log_git_versions binutils-gdb "${BINUTILS_GDB_SOURCE_DIR}" \
                 gcc "${GCC_SOURCE_DIR}" \
                 newlib "${NEWLIB_SOURCE_DIR}" \
                 qemu "${QEMU_SOURCE_DIR}" \
                 beebs "${BEEBS_SOURCE_DIR}"
job_done

# ====================================================================
#                            Build tools
# ====================================================================

build_binutils_gdb
build_gcc_stage_1
build_newlib
build_gcc_stage_2
build_qemu

# ====================================================================
#                           Finished
# ====================================================================

SCRIPT_END_TIME=`date +%s`
TIME_STR=`times_to_time_string ${SCRIPT_START_TIME} ${SCRIPT_END_TIME}`
echo "All finished ${TIME_STR}." | tee -a ${LOGFILE}
