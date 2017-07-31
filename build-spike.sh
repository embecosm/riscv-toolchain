#!/bin/bash

# Check we have verilator
if ! test $(which verilator)
then
    echo "ERROR: verilator required for building the GDB Server"
    exit 1
fi

if ! test $(which dtc)
then
    echo "ERROR: device-tree-compiler (dtc) required to build SPIKE"
    exit 1
fi


TOOLCHAIN_DIR=$(cd "`dirname \"$0\"`"; pwd)
TOP=$(cd ${TOOLCHAIN_DIR}/..; pwd)

# ====================================================================

WITH_TARGET=riscv32-unknown-elf
WITH_ARCH=rv32i
CLEAN_BUILD=no
DEBUG_BUILD=no
BUILD_DIR=${TOP}/build
INSTALL_DIR=${TOP}/install
VERILATOR_DIR=`pkg-config --variable=prefix verilator`
SPIKE_SRC_DIR=${TOP}/riscv-isa-sim
JOBS=
LOAD=

# ====================================================================

function usage () {
    MSG=$1

    echo "${MSG}"
    echo
    echo "Usage: ./build-targets.sh [--build-dir <build_dir>]"
    echo "                          [--install-dir <install_dir>]"
    echo "                          [--jobs <count>] [--load <load>]"
    echo "                          [--spike-source <source_dir>]"
    echo "                          [--single-thread]"
    echo "                          [--clean]"
    echo "                          [--debug]"
    echo "                          [--with-target <target>]"
    echo "                          [--with-arch <arch>]"
    echo
    echo "Defaults:"
    echo "   --with-target riscv32-unknown-elf"
    echo "   --with-arch rv32ima"

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

    --spike-source)
	shift
	spike_src_dir=$1
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
	WITH_TARGET=$1
	;;

    --with-arch)
	shift
	WITH_ARCH=$1
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

FESVR_BUILD_DIR=${BUILD_DIR}/riscv-fesvr
PK_BUILD_DIR=${BUILD_DIR}/riscv-pk
SPIKE_BUILD_DIR=${BUILD_DIR}/riscv-isa-sim

echo "                Top: ${TOP}"
echo "          Toolchain: ${TOOLCHAIN_DIR}"
echo "          Build Dir: ${BUILD_DIR}"
echo "        Install Dir: ${INSTALL_DIR}"
echo "    SPIKE Build Dir: ${SPIKE_BUILD_DIR}"
echo "   SPIKE Source Dir: ${SPIKE_SRC_DIR}"

if [ "x${CLEAN_BUILD}" = "xyes" ]
then
    for T in `seq 5 -1 1`
    do
	echo -ne "\rClean Build: yes (in ${T} seconds)"
	sleep 1
    done
    echo -e "\rClean Build: yes                           "
    rm -fr ${SPIKE_BUILD_DIR}
else
    echo "Clean Build: no"
fi

if [ "x${DEBUG_BUILD}" = "xyes" ]
then
    export CFLAGS="-g3 -O0"
    export CXXFLAGS="-g3 -O0"
fi

# Default parallellism
processor_count="`(echo processor; cat /proc/cpuinfo 2>/dev/null echo processor) \
           | grep -c processor`"
if [ "x${JOBS}" == "x" ]; then JOBS=${processor_count}; fi
if [ "x${LOAD}" == "x" ]; then LOAD=${processor_count}; fi
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

# Add Binutils and GCC to path to build newlib
export PATH=${INSTALL_DIR}/bin:$PATH

# ====================================================================
#                Build and Install RISC-V Front-End Server (fesvr)
# ====================================================================

job_start "Building fesvr (RISC-V Front-End Server used by SPIKE)"

mkdir_and_enter ${FESVR_BUILD_DIR}

if ! run_command ${TOP}/riscv-fesvr/configure \
           --prefix=${INSTALL_DIR}
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
           --prefix=${INSTALL_DIR} \
           --host=${WITH_TARGET}
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

if ! run_command ${SPIKE_SRC_DIR}/configure \
           --prefix=${INSTALL_DIR} \
           --with-fesvr=${INSTALL_DIR} \
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
