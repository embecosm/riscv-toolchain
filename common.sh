set -u

if [ "x${LOGFILE}" == "x" ]; then
    echo "LOGFILE unset"
    exit 1
fi
if [ "x${SCRIPT_START_TIME}" == "x" ]; then
    echo "SCRIPT_START_TIME unset"
    exit 1
fi

function msg ()
{
    echo "$1" | tee -a ${LOGFILE}
}

function error ()
{
    echo "!! $1" | tee -a ${LOGFILE}

    all_finished

    echo ""
    echo "See ${LOGFILE} for more details"
    echo ""

    cat ${LOGFILE}

    exit 1
}

function all_finished ()
{
    SCRIPT_END_TIME=`date +%s`
    TIME_STR=`times_to_time_string ${SCRIPT_START_TIME} ${SCRIPT_END_TIME}`

    echo "All finished ${TIME_STR}." | tee -a ${LOGFILE}
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
    if [ -z "${JOB_START_TIME}" ]; then
	echo "Attempt to end a job which has not been started"
	exit 1
    fi

    local JOB_END_TIME=`date +%s`
    local TIME_STR=`times_to_time_string ${JOB_START_TIME} ${JOB_END_TIME}`

    echo "Finished ${TIME_STR}." >> ${LOGFILE}
    echo -e "\r${JOB_TITLE} completed ${TIME_STR}."

    JOB_TITLE=""
    JOB_START_TIME=
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

function log_git_versions ()
{
    echo "" >> ${LOGFILE}
    echo "Git Versions:" >> ${LOGFILE}
    until test -z ${1:-}
    do
        name=$1
        shift
        dir=$1
        shift

        echo -n "  $name: " >> ${LOGFILE}

        if test -d "${dir}"
        then
            pushd `pwd` &>/dev/null
            cd $dir

            sha=`git rev-parse HEAD 2>/dev/null`
            if test $? -eq 0
            then
                echo -n "${sha}" >> ${LOGFILE}
            else
                echo -n "git rev-parse failed" >> ${LOGFILE}
            fi

            desc=`git describe --dirty --always 2>/dev/null`
            if test $? -eq 0
            then
                echo "  ($desc)" >> ${LOGFILE}
            else
                echo "" >> ${LOGFILE}
            fi

            popd &>/dev/null
        else
            echo "No directory found" >> ${LOGFILE}
        fi
    done
    echo "" >> ${LOGFILE}
}
