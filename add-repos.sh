#!/bin/sh

# Script to add upstream repos for the RISC-V tool chain

# Copyright (C) 2009, 2013, 2014, 2015, 2016, 2017 Embecosm Limited
# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# This file is part of the Embecosm GNU toolchain build system for RISC-V.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.

# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.
# This file is part of the Embecosm LLVM build system for AAP.

#		    SCRIPT TO CLONE THE RISC-V TOOL CHAIN
#		    =====================================

# Invocation status

# Invocation Syntax

#     add-repos.sh

# Set the top level directory.
topdir=$(cd $(dirname $0)/..;pwd)

BASE_URL=git@github.com:embecosm

cd ${topdir}

# GCC

echo "Getting upstream GCC"

cd ${topdir}/gcc

if git remote | grep -q origin
then
    git remote rename origin embecosm && true;
fi

if ! git remote | grep -q upstream
then
    git remote add upstream git://gcc.gnu.org/git/gcc.git
    git config --add remote.upstream.fetch 'refs/remotes/*:refs/remotes/svn/*'
fi

git fetch upstream
git checkout -b trunk svn/trunk

cd ${topdir}/binutils-gdb

if git remote | grep -q origin
then
    git remote rename origin embecosm && true;
fi

# binutils-gdb

echo "Getting upstream binutils-gdb"

cd ${topdir}/binutils-gdb

if git remote | grep -q origin
then
    git remote rename origin embecosm && true;
fi

if ! git remote | grep -q upstream
then
    git remote add upstream git://sourceware.org/git/binutils-gdb.git
fi

git fetch upstream

if git branch | grep -q master
then
    echo "Warning local copy of master branch already exists for binutils-gdb"
    echo "Delete local copy (git branch -D master) and rerun this script"
else
    git checkout upstream/master
    git checkout -b master
    git branch -u master upstream/master
fi

# newlib

echo "Getting upstream newlib"

cd ${topdir}/newlib

if git remote | grep -q origin
then
    git remote rename origin embecosm && true;
fi

if ! git remote | grep -q upstream
then
    git remote add upstream git://sourceware.org/git/newlib-cygwin.git
fi

git fetch upstream

if git branch | grep -q master
then
    echo "Warning local copy of master branch already exists for newlib"
    echo "Delete local copy (git branch -D master) and rerun this script"
else
    git checkout upstream/master
    git checkout -b master
    git branch -u master upstream/master
fi

# Emulator: Nothing to do for now.
