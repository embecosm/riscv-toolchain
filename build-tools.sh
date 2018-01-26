#!/bin/bash

TOOLCHAIN_DIR=$(cd "`dirname \"$0\"`"; pwd)
TOP=$(cd ${TOOLCHAIN_DIR}/..; pwd)

# ====================================================================

GDBSERVER_ONLY=no
SKIP_GCC_STAGE_1=no
CLEAN_BUILD=no
DEBUG_BUILD=no
BUILD_DIR=${TOP}/build
VERILATOR_DIR=`pkg-config --variable=prefix verilator`
INSTALL_DIR=${TOP}/install

# ====================================================================

PICORV32_BUILD_DIR=${BUILD_DIR}/picorv32
RI5CY_BUILD_DIR=${BUILD_DIR}/ri5cy

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
    echo "                        [--with-xlen <xlen>]"
    echo "                        [--clean]"
    echo "                        [--debug]"
    echo "                        [--picorv32-build-dir <picorv32_build_dir>]"
    echo "                        [--ri5cy-build-dir <ri5cy_build_dir>]"
    echo "                        [--jobs <count>] [--load <load>]"
    echo "                        [--single-thread]"
    echo "                        [--gdbserver-only]"
    echo "                        [--skip-gcc-stage-1]"
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
    echo "        GCC will select based on the value passed in--with-arch."

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

    --picorv32-build-dir)
	shift
	PICORV32_BUILD_DIR=$(realpath -m $1)
	;;

    --ri5cy-build-dir)
	shift
	RI5CY_BUILD_DIR=$(realpath -m $1)
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

    --gdbserver-only)
	GDBSERVER_ONLY=yes
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
    WITH_ARCH=im
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
    ABI_FLAG=""
else
    ABI_FLAG="--with-abi=${WITH_ABI}"
fi

if [ "${TARGET_SPECIFIED}" == "no" ]
then
    TARGET_TRIPLET=riscv${WITH_XLEN}-unknown-elf
fi

# ====================================================================

# Check that we have a valid VERILATOR_DIR value, otherwise we'll not
# spot until we try to build verilator.
if [ -z "${VERILATOR_DIR}" -o ! -d "${VERILATOR_DIR}" ]
then
    echo "Failed to get header directory from verilator"
    exit 1
fi

# ====================================================================

WITH_ARCH=rv${WITH_XLEN}${WITH_ARCH}

# ====================================================================

BINUTILS_BUILD_DIR=${BUILD_DIR}/binutils
GDB_BUILD_DIR=${BUILD_DIR}/gdb
GCC_STAGE_1_BUILD_DIR=${BUILD_DIR}/gcc-stage1
GCC_STAGE_2_BUILD_DIR=${BUILD_DIR}/gcc-stage2
NEWLIB_BUILD_DIR=${BUILD_DIR}/newlib
GDBSERVER_BUILD_DIR=${BUILD_DIR}/gdbserver
DEJAGNU_BUILD_DIR=${BUILD_DIR}/dejagnu

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

INSTALL_DIR=${INSTALL_PREFIX_DIR}

# ====================================================================

echo "               Top: ${TOP}"
echo "         Toolchain: ${TOOLCHAIN_DIR}"
echo "            Target: ${TARGET_TRIPLET}"
echo "              Xlen: ${WITH_XLEN}"
echo "              Arch: ${WITH_ARCH}"
if [ "${ABI_SPECIFIED}" = "yes" ]
then
    echo "               ABI: ${WITH_ABI}"
fi
echo "       Debug build: ${DEBUG_BUILD}"
echo "         Build Dir: ${BUILD_DIR}"
echo "PICORV32 Build Dir: ${PICORV32_BUILD_DIR}"
echo "   RI5CY Build Dir: ${RI5CY_BUILD_DIR}"
echo "       Install Dir: ${INSTALL_DIR}"

if [ "x${CLEAN_BUILD}" = "xyes" ]
then
    for T in `seq 5 -1 1`
    do
	echo -ne "\r       Clean Build: yes (in ${T} seconds)"
	sleep 1
    done
    echo -e "\r       Clean Build: yes                           "
    if [ "x${GDBSERVER_ONLY}" = "xno" ]
    then
        rm -fr ${BINUTILS_BUILD_DIR} ${GDB_BUILD_DIR} \
           ${GCC_STAGE_1_BUILD_DIR} ${NEWLIB_BUILD_DIR} \
           ${GCC_STAGE_2_BUILD_DIR} ${GDBSERVER_BUILD_DIR}
    else
        rm -fr ${GDBSERVER_BUILD_DIR}
    fi
else
    echo "       Clean Build: no"
fi

if [ "x${DEBUG_BUILD}" = "xyes" ]
then
    export CFLAGS="-g3 -O0"
    export CXXFLAGS="-g3 -O0"
fi

if [ ! -e ${PICORV32_BUILD_DIR} ]
then
    echo "PICORV32 build directory does not exist"
    exit 1
fi

if [ ! -e ${RI5CY_BUILD_DIR} ]
then
    echo "RI5CY build directory does not exist"
    exit 1
fi

# ====================================================================

JOB_START_TIME=
JOB_TITLE=

SCRIPT_START_TIME=`date +%s`

LOGDIR=${TOP}/logs
LOGFILE=${LOGDIR}/build-$(date +%F-%H%M).log

echo "          Log file: ${LOGFILE}"
echo "          Start at: "`date`
echo "          Parallel: ${PARALLEL}"
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

BINUTILS_SOURCE_DIR=${TOP}/binutils
GDB_SOURCE_DIR=${TOP}/gdb
GCC_SOURCE_DIR=${TOP}/gcc
NEWLIB_SOURCE_DIR=${TOP}/newlib
GDBSERVER_SOURCE_DIR=${TOP}/gdbserver

# ====================================================================
#                Log git versions into the build log
# ====================================================================

job_start "Writing git versions to log file"
log_git_versions binutils "${BINUTILS_SOURCE_DIR}" \
                 gdb "${GDB_SOURCE_DIR}" \
                 gcc "${GCC_SOURCE_DIR}" \
                 newlib "${NEWLIB_SOURCE_DIR}" \
                 gdbserver "${GDBSERVER_SOURCE_DIR}"
job_done

# ====================================================================
#                   Build and install binutils
# ====================================================================

if [ "x${GDBSERVER_ONLY}" = "xno" ]
then

job_start "Building binutils"

mkdir_and_enter "${BINUTILS_BUILD_DIR}"

if ! run_command ${TOP}/binutils/configure \
         --prefix=${INSTALL_PREFIX_DIR} \
         --sysconfdir=${INSTALL_SYSCONF_DIR} \
         --localstatedir=${INSTALL_LOCALSTATE_DIR} \
         --disable-gtk-doc \
         --disable-gtk-doc-html \
         --disable-doc \
         --disable-docs \
         --disable-documentation \
         --with-xmlto=no \
         --with-fop=no \
         --disable-multilib \
         --target=${TARGET_TRIPLET} \
         --with-sysroot=${SYSROOT_DIR} \
         --enable-poison-system-directories \
         --disable-tls \
         --disable-gdb \
         --disable-libdecnumber \
         --disable-readline \
         --enable-shared \
         --disable-sim
then
    error "Failed to configure binutils"
fi

if ! run_command make ${PARALLEL}
then
    error "Failed to build binutils"
fi

if ! run_command make ${PARALLEL} install
then
    error "Failed to install binutils"
fi

job_done

fi

# ====================================================================
#                   Build and install GDB and sim
# ====================================================================

if [ "x${GDBSERVER_ONLY}" = "xno" ]
then

job_start "Building GDB and sim"

mkdir_and_enter "${GDB_BUILD_DIR}"

if ! run_command ${TOP}/gdb/configure \
         --prefix=${INSTALL_PREFIX_DIR} \
         --sysconfdir=${INSTALL_SYSCONF_DIR} \
         --localstatedir=${INSTALL_LOCALSTATE_DIR} \
         --disable-gtk-doc \
         --disable-gtk-doc-html \
         --disable-doc \
         --disable-docs \
         --disable-documentation \
         --with-xmlto=no \
         --with-fop=no \
         --disable-multilib \
         --target=${TARGET_TRIPLET} \
         --with-sysroot=${SYSROOT_DIR} \
         --enable-poison-system-directories \
         --disable-tls \
         --disable-gprof \
         --disable-ld \
         --disable-gas \
         --disable-binutils
then
    error "Failed to configure GDB and sim"
fi

if ! run_command make ${PARALLEL}
then
    error "Failed to build GDB and sim"
fi

if ! run_command make ${PARALLEL} install
then
    error "Failed to install GDB and sim"
fi

job_done

fi

# ====================================================================
#                Build and Install GCC (Stage 1)
# ====================================================================

if [ "x${GDBSERVER_ONLY}" = "xno" ]
then

if [ "x${SKIP_GCC_STAGE_1}" = "xno" ]
then
    job_start "Building stage 1 GCC"

    mkdir_and_enter ${GCC_STAGE_1_BUILD_DIR}

    if ! run_command ${TOP}/gcc/configure \
               --prefix="${INSTALL_PREFIX_DIR}" \
               --sysconfdir="${INSTALL_SYSCONF_DIR}" \
               --localstatedir="${INSTALL_LOCALSTATE_DIR}" \
               --disable-shared \
               --disable-static \
               --disable-gtk-doc \
               --disable-gtk-doc-html \
               --disable-doc \
               --disable-docs \
               --disable-documentation \
               --with-xmlto=no \
               --with-fop=no \
               --target=${TARGET_TRIPLET} \
               --with-sysroot=${SYSROOT_DIR} \
               --disable-__cxa_atexit \
               --with-gnu-ld \
               --disable-libssp \
               --disable-multilib \
               --enable-target-optspace \
               --disable-libsanitizer \
               --disable-tls \
               --disable-libmudflap \
               --disable-threads \
               --disable-libquadmath \
               --disable-libgomp \
               --without-isl \
               --without-cloog \
               --disable-decimal-float \
               --with-arch=${WITH_ARCH} \
               ${ABI_FLAG} \
               --enable-languages=c \
               --without-headers \
               --with-newlib \
               --disable-largefile \
               --disable-nls \
               --enable-checking=yes
    then
        error "Failed to configure GCC (stage 1)"
    fi

    if ! run_command make ${PARALLEL} all-gcc
    then
        error "Failed to build GCC (stage 1)"
    fi

    if ! run_command make ${PARALLEL} install-gcc
    then
        error "Failed to install GCC (stage 1)"
    fi
else
    job_start "Skipping stage 1 GCC"
fi

job_done

fi

# ====================================================================
#                   Build and install newlib
# ====================================================================

if [ "x${GDBSERVER_ONLY}" = "xno" ]
then

job_start "Building newlib"

# Add Binutils and GCC to path to build newlib
export PATH=${INSTALL_PREFIX_DIR}/bin:$PATH

mkdir_and_enter "${NEWLIB_BUILD_DIR}"

if ! run_command ${TOP}/newlib/configure \
         --prefix=${INSTALL_PREFIX_DIR} \
         --sysconfdir=${INSTALL_SYSCONF_DIR} \
         --localstatedir=${INSTALL_LOCALSTATE_DIR} \
         --target=${TARGET_TRIPLET} \
         --with-sysroot=${SYSROOT_DIR}
then
    error "Failed to configure newlib"
fi

if ! run_command make ${PARALLEL}
then
    error "Failed to build newlib"
fi

if ! run_command make ${PARALLEL} install
then
    error "Failed to install newlib"
fi

job_done

fi

# ====================================================================
#                Build and Install GCC (Stage 2)
# ====================================================================

if [ "x${GDBSERVER_ONLY}" = "xno" ]
then

job_start "Building stage 2 GCC"

mkdir_and_enter ${GCC_STAGE_2_BUILD_DIR}

if ! run_command ${TOP}/gcc/configure \
           --prefix="${INSTALL_PREFIX_DIR}" \
           --sysconfdir="${INSTALL_SYSCONF_DIR}" \
           --localstatedir="${INSTALL_LOCALSTATE_DIR}" \
           --disable-shared \
           --enable-static \
           --disable-gtk-doc \
           --disable-gtk-doc-html \
           --disable-doc \
           --disable-docs \
           --disable-documentation \
           --with-xmlto=no \
           --with-fop=no \
           --target=${TARGET_TRIPLET} \
           --with-sysroot=${SYSROOT_DIR} \
           --disable-__cxa_atexit \
           --with-gnu-ld \
           --disable-libssp \
           --disable-multilib \
           --enable-target-optspace \
           --disable-libsanitizer \
           --disable-tls \
           --disable-libmudflap \
           --disable-threads \
           --disable-libquadmath \
           --disable-libgomp \
           --without-isl \
           --without-cloog \
           --disable-decimal-float \
           --with-arch=${WITH_ARCH} \
           ${ABI_FLAG} \
           --enable-languages=c,c++ \
           --with-newlib \
           --disable-largefile \
           --disable-nls \
           --enable-checking=yes \
           --with-build-time-tools=${INSTALL_PREFIX_DIR}/${TARGET_TRIPLET}/bin
then
    error "Failed to configure GCC (stage 2)"
fi

if ! run_command make ${PARALLEL} all
then
    error "Failed to build GCC (stage 2)"
fi

if ! run_command make ${PARALLEL} install
then
    error "Failed to install GCC (stage 2)"
fi

job_done

fi

# ====================================================================
#                Build and Install DejaGNU
# ====================================================================

if [ "x${GDBSERVER_ONLY}" = "xno" ]
then

job_start "Building DejaGNU"

mkdir_and_enter ${DEJAGNU_BUILD_DIR}

if ! run_command ${TOP}/dejagnu/configure \
           --prefix="${INSTALL_PREFIX_DIR}"
then
    error "Failed to configure DejaGNU"
fi

if ! run_command make
then
    error "Failed to build DejaGNU"
fi

if ! run_command make install
then
    error "Failed to install DejaGNU"
fi

job_done

fi

# ====================================================================
#             Build GDB Server for provided targets
# ====================================================================

echo "PICORV32 for GDBServer: ${PICORV32_BUILD_DIR}"
echo "   RI5CY for GDBServer: ${RI5CY_BUILD_DIR}"

job_start "Building GDB Server for provided targets"

cd ${TOP}/gdbserver

if ! run_command autoreconf --install
then
    error "Failed to autoreconf for GDB Server"
fi

mkdir_and_enter ${GDBSERVER_BUILD_DIR}

GDBSERVER_CONFIG_ARGS="\
    --with-verilator-headers=${VERILATOR_DIR}/share/verilator/include \
    --prefix=${TOP}/install"
GDBSERVER_CONFIG_ARGS="${GDBSERVER_CONFIG_ARGS} \
    --with-ri5cy-modeldir=${RI5CY_BUILD_DIR}/verilator-model/obj_dir \
    --with-ri5cy-topmodule=top"
GDBSERVER_CONFIG_ARGS="${GDBSERVER_CONFIG_ARGS} \
    --with-picorv32-modeldir=${PICORV32_BUILD_DIR}/obj_dir \
    --with-picorv32-topmodule=testbench"
GDBSERVER_CONFIG_ARGS="${GDBSERVER_CONFIG_ARGS} \
    --with-binutils-incdir=${INSTALL_DIR}/x86_64-pc-linux-gnu/${TARGET_TRIPLET}/include \
    --with-binutils-libdir=${INSTALL_DIR}/x86_64-pc-linux-gnu/${TARGET_TRIPLET}/lib"


if ! run_command ${TOP}/gdbserver/configure ${GDBSERVER_CONFIG_ARGS}
then
    error "Failed to configure GDB Server"
fi

if ! run_command make clean
then
    error "Failed to make clean for GDB Server"
fi

if ! run_command make
then
    error "Failed to build GDB Server"
fi

if ! run_command make install
then
    error "Failed to install GDB Server"
fi

job_done


# ====================================================================
#                           Finished
# ====================================================================

all_finished
