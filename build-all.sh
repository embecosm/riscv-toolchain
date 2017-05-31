#!/bin/bash

TOOLCHAIN_DIR=$(cd "`dirname \"$0\"`"; pwd)
TOP=$(cd ${TOOLCHAIN_DIR}/..; pwd)

# ====================================================================

# Architecture is rv32ima because riscv-sim doesn't support the C
# extension. However, note that the HiFive1 is rv32imac.

WITH_TARGET=riscv32-unknown-elf
WITH_ARCH=rv32ima
WITH_ABI=ilp32
SKIP_GCC_STAGE_1=no
CLEAN_BUILD=no
BUILD_DIR=${TOP}/build
INSTALL_DIR=${TOP}/install
JOBS=
LOAD=

# Uncomment for everything to be built with debugging. This will make
# the toolchain very slow.

#export CFLAGS="-g -O0"
#export CXXFLAGS="-g -O0"

# ====================================================================

function usage () {
    MSG=$1

    echo "${MSG}"
    echo
    echo "Usage: ./build-all.sh [--build-dir <build_dir>]"
    echo "                      [--install-dir <install_dir>]"
    echo "                      [--jobs <count>] [--load <load>]"
    echo "                      [--single-thread]"
    echo "                      [--clean]"
    echo "                      [--skip-gcc-stage-1]"
    echo "                      [--with-target <target>]"
    echo "                      [--with-arch <arch>]"
    echo "                      [--with-abi <abi>]"
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

# ====================================================================

TARGET_TRIPLET=${WITH_TARGET}

echo "        Top: ${TOP}"
echo "  Toolchain: ${TOOLCHAIN_DIR}"
echo "     Target: ${TARGET_TRIPLET}"
echo "       Arch: ${WITH_ARCH}"
echo "        ABI: ${WITH_ABI}"
echo "  Build Dir: ${BUILD_DIR}"
echo "Install Dir: ${INSTALL_DIR}"

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

BINUTILS_BUILD_DIR=${BUILD_DIR}/binutils
GDB_BUILD_DIR=${BUILD_DIR}/gdb
GCC_STAGE_1_BUILD_DIR=${BUILD_DIR}/gcc-stage-1
GCC_STAGE_2_BUILD_DIR=${BUILD_DIR}/gcc-stage-2
NEWLIB_BUILD_DIR=${BUILD_DIR}/newlib
DEJAGNU_BUILD_DIR=${BUILD_DIR}/dejagnu
FESVR_BUILD_DIR=${BUILD_DIR}/riscv-fesvr
PK_BUILD_DIR=${BUILD_DIR}/riscv-pk
SPIKE_BUILD_DIR=${BUILD_DIR}/riscv-isa-sim

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
echo "   Parellel: ${PARALLEL}"
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

function msg ()
{
    echo "$1" | tee -a ${LOGFILE}
}

function error ()
{
    SCRIPT_END_TIME=`date +%s`
    TIME_STR=`times_to_time_string ${SCRIPT_START_TIME} ${SCRIPT_END_TIME}`

    echo "!! $1" | tee -a ${LOGFILE}
    echo "All finished ${TIME_STR}." | tee -a ${LOGFILE}
    echo ""
    echo "See ${LOGFILE} for more details"

    exit 1
}

function times_to_time_string ()
{
    local START=$1
    local END=$2

    local TIME_TAKEN=$((END - START))
    local TIME_STR=""

    if [ ${TIME_TAKEN} -gt 0 ]
    then
        local MINS=$((TIME_TAKEN / 60))
        local SECS=$((TIME_TAKEN - (60 * MINS)))
        local MIN_STR=""
        local SEC_STR=""
        if [ ${MINS} -gt 1 ]
        then
            MIN_STR=" ${MINS} minutes"
        elif [ ${MINS} -eq 1 ]
        then
            MIN_STR=" ${MINS} minute"
        fi
        if [ ${SECS} -gt 1 ]
        then
            SEC_STR=" ${SECS} seconds"
        elif [ ${SECS} -eq 1 ]
        then
            SEC_STR=" ${SECS} second"
        fi

        TIME_STR="in${MIN_STR}${SEC_STR}"
    else
        TIME_STR="instantly"
    fi

    echo "${TIME_STR}"
}

function job_start ()
{
    JOB_TITLE=$1
    JOB_START_TIME=`date +%s`
    echo "Starting: ${JOB_TITLE}" >> ${LOGFILE}
    echo -n ${JOB_TITLE}"..."
}

function job_done ()
{
    local JOB_END_TIME=`date +%s`
    local TIME_STR=`times_to_time_string ${JOB_START_TIME} ${JOB_END_TIME}`

    echo "Finished ${TIME_STR}." >> ${LOGFILE}
    echo -e "\r${JOB_TITLE} completed ${TIME_STR}."

    JOB_TITLE=""
    JOB_START_TIME=0
}

function mkdir_and_enter ()
{
    DIR=$1

    if ! mkdir -p ${DIR} >> ${LOGFILE} 2>&1
    then
       error "Failed to create directory: ${DIR}"
    fi

    if ! cd ${DIR} >> ${LOGFILE} 2>&1
    then
       error "Failed to entry directory: ${DIR}"
    fi
}

function run_command ()
{
    echo "" >> ${LOGFILE}
    echo "Current directory: ${PWD}" >> ${LOGFILE}
    echo -n "Running: " >> ${LOGFILE}
    for P in "$@"
    do
        V=`echo ${P} | sed -e 's/"/\\\\"/g'`
        echo -n "\"${V}\" " >> ${LOGFILE}
    done
    echo "" >> ${LOGFILE}
    echo "" >> ${LOGFILE}

    "$@" >> ${LOGFILE} 2>&1
    return $?
}

# ====================================================================
#                   Build and install binutils
# ====================================================================

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


# ====================================================================
#                   Build and install GDB and sim
# ====================================================================

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


# ====================================================================
#                Build and Install GCC (Stage 1)
# ====================================================================

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


# ====================================================================
#                   Build and install newlib
# ====================================================================

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


# ====================================================================
#                Build and Install GCC (Stage 2)
# ====================================================================

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


# ====================================================================
#                Build and Install DejaGNU
# ====================================================================

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


# ====================================================================
#                Build and Install RISC-V Front-End Server (fesvr)
# ====================================================================

job_start "Building fesvr (RISC-V Front-End Server used by SPIKE)"

mkdir_and_enter ${FESVR_BUILD_DIR}

if ! run_command ${TOP}/riscv-fesvr/configure \
           --prefix=${INSTALL_PREFIX_DIR}
then
    error "Failed to configure fesvr"
fi

if ! run_command make install
then
    error "Failed to build and install fesvr"
fi

job_done


# ====================================================================
#                Build and Install RISC-V Proxy Kernel (pk)
# ====================================================================

job_start "Building pk (RISC-V Proxy Kernel used by SPIKE)"

mkdir_and_enter ${PK_BUILD_DIR}

if ! run_command ${TOP}/riscv-pk/configure \
           --prefix=${INSTALL_PREFIX_DIR} \
           --host=${TARGET_TRIPLET}
then
    error "Failed to configure pk"
fi

if ! run_command make
then
    error "Failed to build pk"
fi

if ! run_command make install
then
    error "Failed to install pk"
fi

job_done


# ====================================================================
#                Build and Install RISC-V ISA Simulator (SPIKE)
# ====================================================================

job_start "Building SPIKE (RISC-V ISA Simulator)"

mkdir_and_enter ${SPIKE_BUILD_DIR}

if ! run_command ${TOP}/riscv-isa-sim/configure \
           --prefix=${INSTALL_PREFIX_DIR} \
           --with-fesvr=${INSTALL_PREFIX_DIR} \
           --with-isa=${WITH_ARCH}
then
    error "Failed to configure SPIKE"
fi

if ! run_command make
then
    error "Failed to build SPIKE"
fi

if ! run_command make install
then
    error "Failed to install SPIKE"
fi

job_done


# ====================================================================
#                           Finished
# ====================================================================

SCRIPT_END_TIME=`date +%s`
TIME_STR=`times_to_time_string ${SCRIPT_START_TIME} ${SCRIPT_END_TIME}`
echo "All finished ${TIME_STR}." | tee -a ${LOGFILE}
