#!/bin/bash

TOOLCHAIN_DIR=$(cd "`dirname \"$0\"`"; pwd)
TOP=$(cd ${TOOLCHAIN_DIR}/..; pwd)

# ====================================================================

CLEAN_BUILD=no
DEBUG_BUILD=no
BUILD_DIR=${TOP}/build-arc
INSTALL_DIR=${TOP}/install-arc

# ====================================================================

# These are deliberately left blank, defaults are filled in below as
# appropriate.

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
    echo "                        [--with-target <target>]"
    echo "                        [--with-cpu <cpu>]"
    echo
    echo "--with-target:"
    echo "        Defaults to arc-elf32."
    echo ""
    echo "--with-cpu:"
    echo "        Defaults to archs."

    exit 1
}

TARGET_SPECIFIED=no
CPU_SPECIFIED=no

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

if [ "${TARGET_SPECIFIED}" == "no" ]
then
    TARGET_TRIPLET=arc-elf32
fi

if [ "${CPU_SPECIFIED}" = "no" ]
then
    WITH_CPU=archs
fi

TARGET_GCC_CONFIG_FLAGS="--with-cpu=${WITH_CPU}"

# ====================================================================

echo "               Top: ${TOP}"
echo "         Toolchain: ${TOOLCHAIN_DIR}"
echo "            Target: ${TARGET_TRIPLET}"
echo "               CPU: ${WITH_CPU}"
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
msg  "No QEMU for ARC yet - skipping."
#build_qemu

# ====================================================================
#                           Finished
# ====================================================================

SCRIPT_END_TIME=`date +%s`
TIME_STR=`times_to_time_string ${SCRIPT_START_TIME} ${SCRIPT_END_TIME}`
echo "All finished ${TIME_STR}." | tee -a ${LOGFILE}
