#!/bin/bash
#
# Script to extract opcodes from RISC-V binaries
#
# Copyright (C) 2019 Embecosm Limited
#
# Contributor: Jeremy Bennett <jeremy.bennett@embecosm.com>
#
# This file is part of the Bristol/Embecosm Embedded Benchmark Suite.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.

# SPDX-License-Identifier: GPL-3.0-or-later

# Get arg

progdir="$(dirname $0)"
topdir="$(cd ${progdir}; pwd)"

# Get arg

if [ $# -ne 2 ]
then
    echo "Usage: ${0} <beebsdir> <bindir>"
    exit 1
fi

# Make args absolute

beebsdir="$(cd ${1}; pwd)"
bindir="$(cd ${2}; pwd)"

export PATH=${bindir}:${PATH}

# Set up commands

OBJDUMP=riscv32-unknown-elf-objdump

# Patterns for instructions. For convenience here is a list of all the
# instructions.

# add
# addi
# and
# andi
# beq
# beqz
# bge
# bgeu
# bgez
# bgtz
# blez
# blt
# bltu
# bltz
# bne
# bnez
# div
# divu
# fabs.d
# fadd.d
# fadd.s
# fcvt.d.s
# fcvt.d.w
# fcvt.d.wu
# fcvt.s.d
# fcvt.s.w
# fcvt.w.d
# fcvt.w.s
# fcvt.wu.d
# fdiv.d
# fdiv.s
# feq.d
# feq.s
# fld
# fle.d
# fle.s
# flt.d
# flt.s
# flw
# fmadd.d
# fmadd.s
# fmsub.s
# fmul.d
# fmul.s
# fmv.d
# fmv.s
# fmv.w.x
# fmv.x.w
# fneg.d
# fneg.s
# fnmsub.d
# fnmsub.s
# fsd
# fsub.d
# fsub.s
# fsw
# j
# jal
# jalr
# jr
# lb
# lbu
# lh
# lhu
# li
# lui
# lw
# mul
# mulhsu
# mulhu
# mv
# neg
# not
# or
# ori
# rem
# remu
# ret
# sb
# seqz
# sgtz
# sh
# sll
# slli
# slt
# sltiu
# sltu
# snez
# sra
# srai
# srl
# srli
# sub
# sw
# xor
# xori

# Branches and jumps

bops="\(beq\)\|\(beqz\)\|\(bge\)\|\(bgeu\)\|\(bgez\)\|\(bgtz\)\|\(blez\)\|\(blt\)\|\(bltu\)\|\(bltz\)\|\(bne\)\|\(bnez\)\|\(j\)\|\(jal\)\|\(jalr\)\|\(jr\)\|\(ret\)"

# Loads and stores to and from memory (excludes load immediate)

mops="\(fld\)\|\(flw\)\|\(fsd\)\|\(fsw\)\|\(lb\)\|\(lbu\)\|\(lh\)\|\(lhu\)\|\(lw\)\|\(sb\)\|\(sh\)\|\(sw\)"

# Integer ALU, which includes moves

iops="\(add\)\|\(addi\)\|\(and\)\|\(andi\)\|\(div\)\|\(divu\)\|\(li\)\|\(lui\)\|\(mul\)\|\(mulhsu\)\|\(mulhu\)\|\(mv\)\|\(neg\)\|\(not\)\|\(or\)\|\(ori\)\|\(rem\)\|\(remu\)\|\(seqz\)\|\(sgtz\)\|\(sll\)\|\(slli\)\|\(slt\)\|\(sltiu\)\|\(sltu\)\|\(snez\)\|\(sra\)\|\(srai\)\|\(srl\)\|\(srli\)\|\(sub\)\|\(xor\)\|\(xori\)"

# Floating point, which includes moves, but not loads and stores.

fops="\(fabs\.d\)\|\(fadd\.d\)\|\(fadd\.s\)\|\(fcvt\.d\.s\)\|\(fcvt\.d\.w\)\|\(fcvt\.d\.wu\)\|\(fcvt\.s\.d\)\|\(fcvt\.s\.w\)\|\(fcvt\.w\.d\)\|\(fcvt\.w\.s\)\|\(fcvt\.wu\.d\)\|\(fdiv\.d\)\|\(fdiv\.s\)\|\(feq\.d\)\|\(feq\.s\)\|\(fle\.d\)\|\(fle\.s\)\|\(flt\.d\)\|\(flt\.s\)\|\(fmadd\.d\)\|\(fmadd\.s\)\|\(fmsub\.s\)\|\(fmul\.d\)\|\(fmul\.s\)\|\(fmv\.d\)\|\(fmv\.s\)\|\(fmv\.w\.x\)\|\(fmv\.x\.w\)\|\(fneg\.d\)\|\(fneg\.s\)\|\(fnmsub\.d\)\|\(fnmsub\.s\)\|\(fsub\.d\)\|\(fsub\.s\)"


# Clear the temporary file

tmpf=/tmp/dump-ocodes-$$
rm -f ${tmpf}
touch ${tmpf}

# Find all the binaries to look at

cd ${beebsdir}

printf '"Program","Total","Branch","Memory","Integer","Float"\n'

for d in *
do
    # Binaries are in directories which have an executable of the same name.
    # NOTE. there are some generic directories which have no executable and so
    # we ignore.

    if [ -d "${d}" -a -e "${d}/${d}" ]
    then
	exe="${d}/${d}"
	${OBJDUMP} -d ${exe} |
	    sed -n -e 's/^[ \t]\+[[:xdigit:]]\+:[ \t]\+[[:xdigit:]]\+[ \t]\+\([^ \t]\+\).*$/\1/p' > ${tmpf}

	# Count each category

	n_ops=$(wc -l < ${tmpf})
	n_bops=$(grep -c "^\(${bops}\)" < ${tmpf})
	n_mops=$(grep -c "^\(${mops}\)" < ${tmpf})
	n_iops=$(grep -c "^\(${iops}\)" < ${tmpf})
	n_fops=$(grep -c "^\(${fops}\)" < ${tmpf})

	printf '"%s","%d","%d","%d","%d","%d"\n' "${d}" ${n_ops} ${n_bops} \
	       ${n_mops} ${n_iops} ${n_fops}
    fi
done

rm -r ${tmpf}
