#!/bin/bash

TOOLCHAIN_DIR=$(cd "`dirname \"$0\"`"; pwd)
TOP=$(cd ${TOOLCHAIN_DIR}/..; pwd)

# ====================================================================

CLEAN_BUILD=no

INSTALL_DIR=${TOP}/install
BUILD_DIR=${TOP}/build
JOBS=
LOAD=

# ====================================================================

function usage () {
    MSG=$1

    echo "${MSG}"
    echo
    echo "Usage: ./build-testfloat.sh [--build-dir <build_dir>]"
    echo "                            [--install-dir <install_dir>]"
    echo "                            [--jobs <count>] [--load <load>]"
    echo "                            [--single-thread]"
    echo "                            [--clean]"
    echo

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

TESTFLOAT_BUILD_DIR=${BUILD_DIR}/testfloat

echo "        Top: ${TOP}"
echo "  Toolchain: ${TOOLCHAIN_DIR}"
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
    rm -fr ${TESTFLOAT_BUILD_DIR}
else
    echo "Clean Build: no"
fi

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
LOGFILE=${LOGDIR}/build-testfloat-$(date +%F-%H%M).log

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
#                        Build TestFloat
# ====================================================================

job_start "Building testfloat"

mkdir_and_enter "${TESTFLOAT_BUILD_DIR}"

TESTFLOAT_BASE=${TOP}/berkeley-testfloat-3
SOFTFLOAT_BASE=${TOP}/berkeley-softfloat-3

# Avoid building in-tree by copying needed files into specified build dir
if ! run_command install -C ${TESTFLOAT_BASE}/build/Linux-386-GCC/Makefile \
           ${TESTFLOAT_BUILD_DIR} ||
   ! run_command install -C ${TESTFLOAT_BASE}/build/Linux-386-GCC/platform.h \
           ${TESTFLOAT_BUILD_DIR}
then
    error "Failed to build testfloat"
fi
  
if ! SOURCE_DIR=${TESTFLOAT_BASE}/source SOFTFLOAT_DIR=${SOFTFLOAT_BASE} \
      run_command make
then
    error "Failed to build testfloat"
fi

if ! run_command install -C ${TESTFLOAT_BUILD_DIR}/testfloat \
           ${INSTALL_DIR}/bin \
   || ! run_command install -C ${TESTFLOAT_BUILD_DIR}/testfloat_gen \
           ${INSTALL_DIR}/bin \
   || ! run_command install -C ${TESTFLOAT_BUILD_DIR}/testfloat_ver \
           ${INSTALL_DIR}/bin \
   || ! run_command install -C ${TESTFLOAT_BUILD_DIR}/testsoftfloat \
           ${INSTALL_DIR}/bin \
   || ! run_command install -C ${TESTFLOAT_BUILD_DIR}/timesoftfloat \
           ${INSTALL_DIR}/bin
then
  error "Failed to install testfloat"
fi

job_done

# ====================================================================
#                           Finished
# ====================================================================

SCRIPT_END_TIME=`date +%s`
TIME_STR=`times_to_time_string ${SCRIPT_START_TIME} ${SCRIPT_END_TIME}`
echo "All finished ${TIME_STR}." | tee -a ${LOGFILE}
