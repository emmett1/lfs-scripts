#!/bin/sh -e

CWD=$PWD
ROOTFS=/tmp/tmprootfs
basepkg="aaa_filesystem linux-headers man-pages glibc tzdata zlib bzip2 xz file readline m4 bc binutils
	gmp mpfr mpc attr acl shadow gcc pkgconf ncurses libcap sed psmisc iana-etc bison flex pcre2 grep bash dash
	libtool gdbm gperf expat inetutils perl perl-xml-parser intltool autoconf automake kmod gettext elfutils
	libffi openssl sqlite python coreutils check diffutils gawk findutils groff less gzip zstd iptables libtirpc iproute2 kbd
	libpipeline make patch man-db tar texinfo vim procps-ng util-linux e2fsprogs sysklogd eudev which
	libarchive pkgutils fakeroot git curl"

for i in $basepkg; do
	if [ ! -f templates/$i/version ]; then
		echo "missing template: $i"
		error=1
	fi
done

[ "$error" ] && exit 1

mkdir -p $ROOTFS/var/lib/pkg
touch $ROOTFS/var/lib/pkg/db
./pkg.sh -i $basepkg --root $ROOTFS

cd $ROOTFS
XZ_DEFAULTS='-T0' tar -cvJpf "$CWD/lfs-rootfs.tar.xz" *
cd $CWD
rm -rf $ROOTFS

exit 0
