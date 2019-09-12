#!/bin/bash

TOOLCHAIN_DIR=$(cd "`dirname \"$0\"`"; pwd)
TOP=$(cd ${TOOLCHAIN_DIR}/..; pwd)

# ====================================================================

CLEAN_BUILD=no
DEBUG_BUILD=no
BUILD_DIR=${TOP}/build-riscv
INSTALL_DIR=${TOP}/install-riscv
MULTILIB_BUILD='--disable-multilib'

# ====================================================================

# These are deliberately left blank, defaults are filled in below as
# appropriate.

WITH_XLEN=
WITH_ARCH=
WITH_ABI=
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
    echo "        Defaults are riscv32-unknown-elf or riscv64-unknown-elf"
    echo "        depending on the value of --with-xlen."
    echo ""
    echo "--with-arch:"
    echo "        Defaults are rv32im or rv64im dependind on the value"
    echo "        of --with-xlen.  Add the 'c' flag for compressed, 'f'"
    echo "        for single precision floating point, and 'd' for double"
    echo "        precision floating point support.  When specifiying, don't"
    echo "        include the 'rv32' or 'rv64' prefix, this will be added"
    echo "        automatically based on the value passed in --with-xlen."
    echo ""
    echo "--with-abi:"
    echo "        Only pass this if you need to override the default that"
    echo "        this script selects for you.  The selected ABI will be"
    echo "        ilp32 or lp64 for 32 or 64 xlen respectively.  The ABI"
    echo "        will be extended with the 'd' or 'f' modifier if 'd' or"
    echo "        'f' is included in the --with-arch value.  The 'd' is"
    echo "        preferred over 'f' if both are present in the arch value"

    exit 1
}

XLEN_SPECIFIED=no
ARCH_SPECIFIED=no
ABI_SPECIFIED=no
TARGET_SPECIFIED=no

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

    --multilib)
	MULTILIB_BUILD='--enable-multilib'
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

    --with-arch)
	shift
	WITH_ARCH=$1
        ARCH_SPECIFIED=yes
	;;

    --with-abi)
	shift
	WITH_ABI=$1
        ABI_SPECIFIED=yes
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

if [ "${ARCH_SPECIFIED}" == "no" ]
then
    WITH_ARCH=imc
else
    case ${WITH_ARCH} in
        rv32* | rv64*)
            echo "Don't include 'rv32' or 'rv64' prefix in --with-arch value ${WITH_ARCH}"
            exit 1
            ;;
    esac
fi

if [ "${ABI_SPECIFIED}" == "no" ]
then
    # The base ABI, matching 32 or 64 bit.
    if [ "${WITH_XLEN}" == "32" ]
    then
        WITH_ABI="ilp32"
    else
        WITH_ABI="lp64"
    fi

    # Now, any floating point extensions to the ABI.
    case ${WITH_ARCH} in
        *d*)
            WITH_ABI="${WITH_ABI}d"
            ;;
        *f*)
            WITH_ABI="${WITH_ABI}f"
            ;;
    esac
fi

if [ "${TARGET_SPECIFIED}" == "no" ]
then
    TARGET_TRIPLET=riscv${WITH_XLEN}-unknown-elf
fi

WITH_ARCH=rv${WITH_XLEN}${WITH_ARCH}

TARGET_GCC_CONFIG_FLAGS="--with-arch=${WITH_ARCH} --with-abi=${WITH_ABI}"
QEMU_TARGETS="riscv64-softmmu,riscv32-softmmu,riscv64-linux-user,riscv32-linux-user"
QEMU_SCRIPTS="riscv32-unknown-elf-run riscv64-unknown-elf-run"

# ====================================================================

echo "               Top: ${TOP}"
echo "         Toolchain: ${TOOLCHAIN_DIR}"
echo "            Target: ${TARGET_TRIPLET}"
echo "              Xlen: ${WITH_XLEN}"
echo "              Arch: ${WITH_ARCH}"
echo "               ABI: ${WITH_ABI}"
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
