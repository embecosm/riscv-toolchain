#!/bin/bash

TOOLCHAIN_DIR=$(cd "`dirname \"$0\"`"; pwd)
TOP=$(cd ${TOOLCHAIN_DIR}/..; pwd)
INSTALL_DIR=${TOP}/install
BUILD_DIR=${TOP}/build
GCC_STAGE_2_BUILD_DIR=${BUILD_DIR}/gcc-stage-2

export DEJAGNU=${TOOLCHAIN_DIR}/site.exp
export PATH=${INSTALL_DIR}/bin:$PATH

function enter_dir ()
{
    DIR=$1
    cd ${DIR}
}

enter_dir ${GCC_STAGE_2_BUILD_DIR}

make check-gcc RUNTESTFLAGS="--target-board=riscv-sim"

