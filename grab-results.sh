#!/bin/sh

# Copyright (C) 2019 Embecosm Limited

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# This file is part of the build system for RISC-V

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.

# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.

# Break out the results from BEEBS runs

if [ $# -ne 1 ]
then
    echo "Usage: grab-results.sh <rootdir>"
    exit 1
fi

rootdir=$(cd $1; pwd)

tests="baseline nocrt nolibc nolibc-nolibgcc nolibc-nolibgcc-nolibm"
archs="riscv arm arc"

for a in ${archs}
do
    for t in ${tests}
    do
	sed < ${rootdir}/build-${a}/beebs-${t}/testsuite/beebs.log \
	    -n -e '/Benchmark               Text/,/Total              /p' |
	    sed -n -e '/^[a-z]/p' |
	    sed -e 's/^\([^ ]\+\)[^0-9]\+\([0-9]\+\)[^0-9]\+\([0-9]\+\)[^0-9]\+\([0-9]\+\)/"\1","\2","\3","\4"/' > ${a}-${t}.csv
    done
done
