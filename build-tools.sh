#!/bin/bash

TOOLCHAIN_DIR=$(cd "`dirname \"$0\"`"; pwd)
TOP=$(cd ${TOOLCHAIN_DIR}/..; pwd)

# ====================================================================

WITH_TARGET=riscv32-unknown-elf
WITH_ARCH=rv32i
WITH_ABI=ilp32
GDBSERVER_ONLY=no
SKIP_GCC_STAGE_1=no
CLEAN_BUILD=no
DEBUG_BUILD=no
BUILD_DIR=${TOP}/build
PICORV32_BUILD_DIR=${BUILD_DIR}/picorv32
RI5CY_BUILD_DIR=${BUILD_DIR}/ri5cy
INSTALL_DIR=${TOP}/install
VERILATOR_DIR=`pkg-config --variable=prefix verilator`
JOBS=
LOAD=

# ====================================================================

function usage () {
    MSG=$1

    echo "${MSG}"
    echo
    echo "Usage: ./build-tools.sh [--build-dir <build_dir>]"
    echo "                        [--install-dir <install_dir>]"
    echo "                        [--picorv32-build-dir <picorv32_build_dir>]"
    echo "                        [--ri5cy-build-dir <ri5cy_build_dir>]"
    echo "                        [--jobs <count>] [--load <load>]"
    echo "                        [--single-thread]"
    echo "                        [--clean]"
    echo "                        [--gdbserver-only]"
    echo "                        [--debug]"
    echo "                        [--skip-gcc-stage-1]"
    echo "                        [--with-target <target>]"
    echo "                        [--with-arch <arch>]"
    echo "                        [--with-abi <abi>]"
    echo
    echo "Defaults:"
    echo "   --with-target riscv32-unknown-elf"
    echo "   --with-arch rv32ima"
    echo "   --with-abi ilp32"

    exit 1
}

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

    --with-target)
	shift
	WITH_TARGET=$1
	;;

    --with-arch)
	shift
	WITH_ARCH=$1
	;;

    --with-abi)
	shift
	WITH_ABI=$1
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

TARGET_TRIPLET=${WITH_TARGET}

echo "               Top: ${TOP}"
echo "         Toolchain: ${TOOLCHAIN_DIR}"
echo "            Target: ${TARGET_TRIPLET}"
echo "              Arch: ${WITH_ARCH}"
echo "               ABI: ${WITH_ABI}"
echo "       Debug build: ${DEBUG_BUILD}"
echo "         Build Dir: ${BUILD_DIR}"
echo "PICORV32 Build Dir: ${PICORV32_BUILD_DIR}"
echo "   RI5CY Build Dir: ${RI5CY_BUILD_DIR}"
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


BINUTILS_BUILD_DIR=${BUILD_DIR}/binutils
GDB_BUILD_DIR=${BUILD_DIR}/gdb
GCC_STAGE_1_BUILD_DIR=${BUILD_DIR}/gcc-stage-1
GCC_STAGE_2_BUILD_DIR=${BUILD_DIR}/gcc-stage-2
NEWLIB_BUILD_DIR=${BUILD_DIR}/newlib
DEJAGNU_BUILD_DIR=${BUILD_DIR}/dejagnu
GDBSERVER_BUILD_DIR=${BUILD_DIR}/gdbserver

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
               --with-abi=${WITH_ABI} \
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
           --with-abi=${WITH_ABI} \
           --enable-languages=c,c++ \
           --with-newlib \
           --disable-largefile \
           --disable-nls \
           --enable-checking=yes \
           --with-build-time-tools=${INSTALL_PREFIX_DIR}/${TARGET_TRIPLET}/bin
then
    error "Failed to configure GCC (stage 2)"
fi

if ! run_command make ${PARALLEL} all-gcc all-target-libgcc
then
    error "Failed to build GCC (stage 2)"
fi

if ! run_command make ${PARALLEL} install-gcc install-target-libgcc
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

SCRIPT_END_TIME=`date +%s`
TIME_STR=`times_to_time_string ${SCRIPT_START_TIME} ${SCRIPT_END_TIME}`
echo "All finished ${TIME_STR}." | tee -a ${LOGFILE}
