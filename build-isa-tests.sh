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
    echo "Usage: ./build-isa-tests.sh [--build-dir <build_dir>]"
    echo "                            [--toolchain-path <toolchain_path>]"
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

    --toolchain-path)
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

# ====================================================================

RISCV_TESTS_BUILD_DIR=${BUILD_DIR}/riscv-tests

echo "                  Top: ${TOP}"
echo "            Toolchain: ${TOOLCHAIN_DIR}"
echo "            Build Dir: ${BUILD_DIR}"
echo "Toolchain Install Dir: ${INSTALL_DIR}"

if [ "x${CLEAN_BUILD}" = "xyes" ]
then
    for T in `seq 5 -1 1`
    do
        echo -ne "\rClean Build: yes (in ${T} seconds)"
        sleep 1
    done
    echo -e "\rClean Build: yes                           "
    rm -fr ${RISCV_TESTS_BUILD_DIR}
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
LOGFILE=${LOGDIR}/build-isa-tests-$(date +%F-%H%M).log

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

function enter_dir ()
{
    DIR=$1

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

# So that riscv32-unknown-elf-gcc, etc. can be found
export PATH=${INSTALL_DIR}/bin:$PATH

# ====================================================================
#                        Build the tests
# ====================================================================

job_start "Building ISA tests"

mkdir_and_enter "${RISCV_TESTS_BUILD_DIR}"

if ! run_command ${TOP}/riscv-tests/configure \
         --with-xlen=32
then
    error "Failed to configure ISA tests"
fi

if ! run_command make isa ${PARALLEL}
then
    error "Failed to build ISA tests"
fi

job_done

# ====================================================================
#                           Finished
# ====================================================================

SCRIPT_END_TIME=`date +%s`
TIME_STR=`times_to_time_string ${SCRIPT_START_TIME} ${SCRIPT_END_TIME}`
echo "All finished ${TIME_STR}." | tee -a ${LOGFILE}
