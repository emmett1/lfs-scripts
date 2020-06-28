#!/bin/sh

. ./config

CWD=$PWD

cd $LFS
tar cvJpf $CWD/toolchain.tar.xz tools

exit 0
