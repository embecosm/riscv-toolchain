#!/bin/bash

TOOLCHAIN_DIR=$(cd "`dirname \"$0\"`"; pwd)
TOP=$(cd ${TOOLCHAIN_DIR}/..; pwd)
INSTALL_DIR=${TOP}/install
BUILD_DIR=${TOP}/build
GCC_STAGE_2_BUILD_DIR=${BUILD_DIR}/gcc-stage-2

export DEJAGNU=${TOOLCHAIN_DIR}/site-spike.exp
export PATH=${INSTALL_DIR}/bin:$PATH

function enter_dir ()
{
    DIR=$1
    cd ${DIR}
}

enter_dir ${GCC_STAGE_2_BUILD_DIR}

make -j 8 check-gcc-c RUNTESTFLAGS="--target-board=riscv-spike"

echo "--------------------------------------------------------------------"
echo "RESULTS FILES (which will be overwritten if you run again) ARE HERE:" 
echo "Complete log: ${GCC_STAGE_2_BUILD_DIR}/gcc/testsuite/gcc/gcc.log"
echo "Summary file: ${GCC_STAGE_2_BUILD_DIR}/gcc/testsuite/gcc/gcc.sum"
