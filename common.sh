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

# ====================================================================
#                   Build and install binutils and GDB
# ====================================================================

function build_binutils_gdb ()
{
    job_start "Building binutils and GDB"

    mkdir_and_enter "${BINUTILS_BUILD_DIR}"

    if ! run_command ${BINUTILS_GDB_SOURCE_DIR}/configure \
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
             --disable-sim
    then
        error "Failed to configure binutils and GDB"
    fi

    if ! run_command make ${PARALLEL}
    then
        error "Failed to build binutils and GDB"
    fi

    if ! run_command make ${PARALLEL} install
    then
        error "Failed to install binutils and GDB"
    fi

    job_done
}

# ====================================================================
#                Build and Install GCC (Stage 1)
# ====================================================================

function build_gcc_stage_1 ()
{
    job_start "Building stage 1 GCC"

    mkdir_and_enter ${GCC_STAGE_1_BUILD_DIR}

    if ! run_command ${GCC_SOURCE_DIR}/configure \
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

    job_done
}

# ====================================================================
#                   Build and install newlib
# ====================================================================

function build_newlib ()
{
    job_start "Building newlib"

    # Add Binutils and GCC to path to build newlib
    export PATH=${INSTALL_PREFIX_DIR}/bin:$PATH

    mkdir_and_enter "${NEWLIB_BUILD_DIR}"

    if ! run_command ${NEWLIB_SOURCE_DIR}/configure \
             --prefix=${INSTALL_PREFIX_DIR} \
             --sysconfdir=${INSTALL_SYSCONF_DIR} \
             --localstatedir=${INSTALL_LOCALSTATE_DIR} \
             --target=${TARGET_TRIPLET} \
             --with-sysroot=${SYSROOT_DIR} \
             CFLAGS_FOR_TARGET="-DPREFER_SIZE_OVER_SPEED=1 -Os" \
            --disable-newlib-fvwrite-in-streamio \
            --disable-newlib-fseek-optimization \
            --enable-newlib-nano-malloc \
            --disable-newlib-unbuf-stream-opt \
            --enable-target-optspace \
            --enable-newlib-reent-small \
            --disable-newlib-wide-orient \
            --disable-newlib-io-float \
            --enable-newlib-nano-formatted-io
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
}

# ====================================================================
#                Build and Install GCC (Stage 2)
# ====================================================================

function build_gcc_stage_2 ()
{
    job_start "Building stage 2 GCC"

    mkdir_and_enter ${GCC_STAGE_2_BUILD_DIR}

    if ! run_command ${GCC_SOURCE_DIR}/configure \
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

    if ! run_command make ${PARALLEL} all
    then
        error "Failed to build GCC (stage 2)"
    fi

    if ! run_command make ${PARALLEL} install
    then
        error "Failed to install GCC (stage 2)"
    fi

    job_done
}

# ====================================================================
#                      Build and Install QEMU
# ====================================================================

function build_qemu ()
{
    job_start "Building QEMU"

    mkdir_and_enter ${QEMU_BUILD_DIR}

    if ! run_command ${QEMU_SOURCE_DIR}/configure \
               --prefix=${INSTALL_DIR} \
               --target-list=riscv64-softmmu,riscv32-softmmu,riscv64-linux-user,riscv32-linux-user
    then
        error "Failed to configure QEMU"
    fi

    if ! run_command make
    then
        error "Failed to build QEMU"
    fi

    if ! run_command make install
    then
        error "Failed to install QEMU"
    fi

    job_done

    # ====================================================================
    #                Copy run scripts to install dir
    # ====================================================================

    job_start "Copying run scripts to install dir"

    if ! run_command cp ${TOOLCHAIN_DIR}/scripts/riscv32-unknown-elf-run ${INSTALL_DIR}/bin
    then
        error "Failed to copy riscv32-unknown-elf-run"
    fi

    if ! run_command cp ${TOOLCHAIN_DIR}/scripts/riscv64-unknown-elf-run ${INSTALL_DIR}/bin
    then
        error "Failed to copy riscv64-unknown-elf-run"
    fi

    job_done
}

