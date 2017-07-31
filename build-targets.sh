#!/bin/bash

# Check we have verilator
if ! test $(which verilator)
then
	echo "ERROR: verilator required for building the GDB Server"
	exit 1
fi


TOOLCHAIN_DIR=$(cd "`dirname \"$0\"`"; pwd)
TOP=$(cd ${TOOLCHAIN_DIR}/..; pwd)

# ====================================================================

CLEAN_BUILD=no
DEBUG_BUILD=no
BUILD_DIR=${TOP}/build
VERILATOR_DIR=`pkg-config --variable=prefix verilator`
PICORV32_SRC_DIR=${TOP}/picorv32
RI5CY_SRC_DIR=${TOP}/ri5cy
JOBS=
LOAD=

# ====================================================================

function usage () {
    MSG=$1

    echo "${MSG}"
    echo
    echo "Usage: ./build-targets.sh [--build-dir <build_dir>]"
    echo "                          [--jobs <count>] [--load <load>]"
    echo "                          [--picorv32-source <source_dir>]"
    echo "                          [--ri5cy-source <source_dir>]"
    echo "                          [--single-thread]"
    echo "                          [--clean]"
    echo "                          [--debug]"

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

    --jobs)
	shift
	JOBS=$1
	;;

    --load)
	shift
	LOAD=$1
	;;

    --picorv32-source)
	shift
	PICORV32_SRC_DIR=$1
	;;

    --ri5cy-source)
	shift
	RI5CY_SRC_DIR=$1
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

PICORV32_BUILD_DIR=${BUILD_DIR}/picorv32
RI5CY_BUILD_DIR=${BUILD_DIR}/ri5cy

echo "                Top: ${TOP}"
echo "          Toolchain: ${TOOLCHAIN_DIR}"
echo "          Build Dir: ${BUILD_DIR}"
echo " PICORV32 Build Dir: ${PICORV32_BUILD_DIR}"
echo "PICORV32 Source Dir: ${PICORV32_SRC_DIR}"
echo "    RI5CY Build Dir: ${RI5CY_BUILD_DIR}"
echo "   RI5CY Source Dir: ${RI5CY_SRC_DIR}"

if [ "x${CLEAN_BUILD}" = "xyes" ]
then
    for T in `seq 5 -1 1`
    do
	echo -ne "\rClean Build: yes (in ${T} seconds)"
	sleep 1
    done
    echo -e "\rClean Build: yes                           "
    rm -fr ${RI5CY_BUILD_DIR} ${PICORV32_BUILD_DIR}
else
    echo "Clean Build: no"
fi

if [ "x${DEBUG_BUILD}" = "xyes" ]
then
    export CFLAGS="-g3 -O0"
    export CXXFLAGS="-g3 -O0"
fi

if [ ! -e ${PICORV32_SRC_DIR} ]
then
    echo "PICORV32 source directory does not exist"
    exit 1
fi
if [ ! -e ${RI5CY_SRC_DIR} ]
then
    echo "RI5CY source directory does not exist"
    exit 1
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
#                Verilate PICORV32
# ====================================================================

job_start "Verilating PICORV32"

rm -rf ${PICORV32_BUILD_DIR}

mkdir_and_enter ${PICORV32_BUILD_DIR}

if ! run_command cp -r ${PICORV32_SRC_DIR}/scripts/gdbserver/* \
          ${PICORV32_BUILD_DIR}
then
    error "Failed to copy files for PICORV32 build"
fi

if ! run_command make
then
    error "Failed to verilate PICORV32"
fi

job_done


# ====================================================================
#                         Verilate RI5CY
# ====================================================================

job_start "Verilating RI5CY"

rm -rf ${RI5CY_BUILD_DIR}

mkdir_and_enter ${RI5CY_BUILD_DIR}

if ! run_command cp -r ${RI5CY_SRC_DIR}/* ${RI5CY_BUILD_DIR}
then
    error "Failed to copy files for RI5CY build"
fi

enter_dir ${RI5CY_BUILD_DIR}/verilator-model

if ! run_command make
then
    error "Failed to verilate R15CY"
fi

job_done


# ====================================================================
#                           Finished
# ====================================================================

SCRIPT_END_TIME=`date +%s`
TIME_STR=`times_to_time_string ${SCRIPT_START_TIME} ${SCRIPT_END_TIME}`
echo "All finished ${TIME_STR}." | tee -a ${LOGFILE}
