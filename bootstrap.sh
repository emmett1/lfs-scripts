#!/bin/sh -e	

_buildtoolchain() {
	if [ "$(id -u)" = 0 ]; then
		echo "temporary toolchain need to build as regular user"
		exit 1
	fi

	export REBUILD=1
	export BOOTSTRAP=1
	export PATH=$TOOLS/bin:$PATH
	export LFS_TGT=x86_64-lfs-linux-gnu
	export LFS_TGT32=i686-lfs-linux-gnu
	
	mkdir -p ${LFS}${TOOLS}
	rm -f $TOOLS
	ln -sv ${LFS}${TOOLS} $TOOLS
	
	for i in $toolchainpkg; do
		[ -f $TOOLS/$i ] && continue
		export tcpkg="$i"
		./pkg.sh ${i%-pass*} || { echo ">> $i failed"; exit 1; }
		touch $TOOLS/$i
		unset tcpkg
	done
	
	TMPPWD=$PWD
	cd $LFS
	rm -f "$TMPPWD/toolchain.tar.xz"
	XZ_DEFAULTS='-T0' tar -cvJpf "$TMPPWD/toolchain.tar.xz" *
	cd $TMPPWD
	
	echo
	echo "toolchain build completed"
}

_compressrootfs() {	
	TMPPWD=$PWD
	cd $LFS
	rm -f "$TMPPWD/lfs-rootfs.tar.xz"
	XZ_DEFAULTS='-T0' tar \
		--exclude='./var/lib/pkg/rejected' \
		--exclude=".$TOOLS" \
		--exclude='./tmp/*' \
		--exclude='./dev/*' \
		--exclude='./sys/*' \
		--exclude='./proc/*' \
		--exclude='./run/*' \
		-cvJpf "$TMPPWD/lfs-rootfs.tar.xz" .
	cd $TMPPWD
	
	echo
	echo "base rootfs is compressed: $TMPPWD/lfs-rootfs.tar.xz"
}

_buildbase() {
	if [ "$(id -u)" != 0 ]; then
		echo "base need to build as root"
		exit 1
	fi
	if [ ! -f $LFS/var/lib/pkg/db ]; then
		mkdir -pv $LFS/bin $LFS/usr/lib $LFS/usr/bin $LFS/etc $LFS/dev || true
		for i in bash cat chmod dd echo ln mkdir pwd rm stty; do
			ln -svf $TOOLS/bin/$i $LFS/bin
		done
		for i in env install perl printf touch; do
			ln -svf $TOOLS/bin/$i $LFS/usr/bin
		done
		ln -svf $TOOLS/lib/libgcc_s.so $TOOLS/lib/libgcc_s.so.1 $LFS/usr/lib
		ln -svf $TOOLS/lib/libstdc++.a $TOOLS/lib/libstdc++.so $TOOLS/lib/libstdc++.so.6 $LFS/usr/lib
		ln -svf bash $LFS/bin/sh
		ln -svf /proc/self/mounts $LFS/etc/mtab
		
		mknod -m 600 $LFS/dev/console c 5 1
		mknod -m 666 $LFS/dev/null c 1 3

		cat > $LFS/etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
EOF

		cat > $LFS/etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
wheel:x:97:
nogroup:x:99:
users:x:999:
EOF

		# pkgutils
		mkdir -p $LFS/var/lib/pkg
		touch $LFS/var/lib/pkg/db
	fi

	install -d -m 1777 $LFS/tmp
	rm -fr $LFS/tmp/lfs-scripts/templates
	mkdir -p $LFS/tmp/lfs-scripts/templates
	cp -r templates/* $LFS/tmp/lfs-scripts/templates
	cp config make.sh pkg.sh $LFS/tmp/lfs-scripts
	
	if [ "$1" = rebuild ]; then
		LFSPATH=/bin:/usr/bin:/sbin:/usr/sbin
		_pkg_opt="-b -u"
	else
		LFSPATH=/bin:/usr/bin:/sbin:/usr/sbin:$TOOLS/bin
		_pkg_opt="-i"
	fi
	
	mountfs
	for i in $basepkg; do
		unset _opt
		case $i in
			aaa_filesystem|gcc|bash|dash|perl|coreutils) _opt=-f;;
		esac
		chroot $LFS env -i PATH=$LFSPATH /tmp/lfs-scripts/pkg.sh -y $i $_pkg_opt $_opt || { umountfs; exit 1; }
		if [ "$1" != rebuild ]; then
			case $i in
				glibc) cat << EOF > $LFS/tmp/glibc-postinstall
#!/bin/sh
[ -f $TOOLS/bin/ld-old ] && exit 0
mv -v $TOOLS/bin/ld $TOOLS/bin/ld-old
mv -v $TOOLS/$(uname -m)-pc-linux-gnu/bin/ld $TOOLS/$(uname -m)-pc-linux-gnu/bin/ld-old
mv -v $TOOLS/bin/ld-new $TOOLS/bin/ld
ln -sv $TOOLS/bin/ld $TOOLS/$(uname -m)-pc-linux-gnu/bin/ld
gcc -dumpspecs | sed -e "s@$TOOLS@@g" -e "/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}" -e '/\*cpp:/{n;s@\$@ -isystem /usr/include@}' > \$(dirname \$(gcc --print-libgcc-file-name))/specs
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose > dummy.log 2>&1
readelf -l a.out | grep ': /lib'
grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
grep -B1 '^ /usr/include' dummy.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
grep "/lib.*/libc.so.6 " dummy.log
grep found dummy.log
rm -v dummy.c a.out dummy.log
EOF
				chroot $LFS env -i PATH=$LFSPATH sh /tmp/glibc-postinstall
				rm -f $LFS/tmp/glibc-postinstall
				;;
			esac
		fi
	done
	umountfs
	
	echo
	echo "base system build completed"
}

mountfs() {
	# unmount first incase already mounted
	umountfs
	mkdir -p $LFS/dev $LFS/run $LFS/proc $LFS/sys
	mount --bind /dev $LFS/dev
	mount -t devpts devpts $LFS/dev/pts -o gid=5,mode=620
	mount -t proc proc $LFS/proc
	mount -t sysfs sysfs $LFS/sys
	mount -t tmpfs tmpfs $LFS/run
	if [ -h $LFS/dev/shm ]; then
	  mkdir -p $LFS/$(readlink $LFS/dev/shm)
	fi
}

umountfs() {
	unmount $LFS/dev/pts
	unmount $LFS/dev
	unmount $LFS/run
	unmount $LFS/proc
	unmount $LFS/sys
}

unmount() {
	while true; do
		mountpoint -q $1 || break
		umount $1 2>/dev/null
	done
}

export LFS=/tmp/lfs-rootfs
export TOOLS=/tmp/lfs-tools
export LC_ALL=C

toolchainpkg="binutils-pass1 gmp mpfr mpc gcc-pass1 linux-headers glibc gcc-pass2 binutils-pass2 gcc-pass3 m4
	ncurses bash bison bzip2 coreutils diffutils file findutils gawk gettext grep gzip make patch perl python
	sed tar texinfo xz openssl ca-certificates curl libarchive pkgutils"
	
basepkg="aaa_filesystem linux-headers man-pages glibc tzdata zlib bzip2 xz file ncurses readline m4 bc binutils
	gmp mpfr mpc attr acl shadow gcc pkgconf libcap sed psmisc iana-etc bison flex pcre2 grep bash dash
	libtool gdbm gperf expat inetutils perl perl-xml-parser intltool autoconf automake openssl kmod gettext elfutils
	libffi sqlite python coreutils check diffutils gawk findutils groff less gzip zstd iptables libtirpc iproute2 kbd
	libpipeline make patch man-db tar texinfo vim procps-ng util-linux e2fsprogs sysklogd eudev which
	libarchive pkgutils fakeroot git ca-certificates curl"
	
if [ ! "$1" ]; then	
	cat << EOF
Usage:
  $0 <options>
  
Options:
  1  build temporary toolchain
  2  build base system (using temporary toolchain)
  3  rebuild base system (without depending on temporary toolchain)
  4  compress base rootfs
EOF
	exit 0
fi
	
case $1 in
	1) _buildtoolchain;;
	2) _buildbase;;
	3) _buildbase rebuild;;
	4) _compressrootfs;;
esac

exit 0
