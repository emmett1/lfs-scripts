#!/bin/sh -e

_auto_patch() {
	if [ -d $CWD/patch ]; then
		for p in $CWD/patch/*.patch; do
			patch ${patch_opt:--Np1} -i $p
		done
	fi
}

_auto_build() {
	if [ -f meson.build ]; then
		_meson_build $@
	elif [ -f configure ]; then
		_configure_build $@
	elif [ -f CMakeLists.txt ]; then
		_cmake_build $@
	elif [ -f setup.py ]; then
		_python3_build $@
	elif [ -f Makefile.PL ]; then
		_perlmodule_build
	elif [ -f Makefile ]; then
		_makefile_build $@
	else
		echo "failed to detect buildtype"
		exit 1
	fi
}

_makefile_build() {
	make || return $?
	make \
		PREFIX=/usr \
		prefix=/usr \
		SYSCONFDIR=/etc \
		sysconfdir=/etc \
		MANDIR=/usr/share/man \
		mandir=/usr/share/man \
		DESTDIR=$PKG install || return $?
}

_perlmodule_build() {
	perl Makefile.PL || return $?
	make || return $?
	make DESTDIR=$PKG install || return $?
}

_cmake_build() {
	mkdir -p cmakebuild
	cd cmakebuild
	cmake -DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_SYSCONFDIR=/etc \
		-DCMAKE_INSTALL_LIBDIR=lib \
		-DCMAKE_INSTALL_LIBEXECDIR=lib \
		-DCMAKE_BUILD_TYPE=Release \
		-DFETCHCONTENT_FULLY_DISCONNECTED=ON \
		-DCMAKE_C_FLAGS_RELEASE="$CFLAGS" \
		-DCMAKE_CXX_FLAGS_RELEASE="$CXXFLAGS" \
		$build_opt  $@ \
		-G Ninja .. || return $?
	if [ -f build.ninja ]; then
		ninja || return $?
		DESTDIR=$PKG ninja install || return $?
	else
		cmake --build build || return $?
		DESTDIR=$PKG cmake --install build || return $?
	fi
}

_python3_build() {
	python3 setup.py build || return $?
	python3 setup.py install --prefix=/usr --root=$PKG --optimize=1 || return $?
}

_configure_build() {
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--libexecdir=/usr/lib \
		--localstatedir=/var \
		--mandir=/usr/share/man \
		$build_opt  $@ || return $?
	make || return $?
	make DESTDIR=$PKG install || return $?
}

_meson_build() {
	meson setup _meson_build \
		--prefix=/usr \
		--libdir=/usr/lib \
		--libexecdir=/usr/lib \
		--bindir=/usr/bin \
		--sbindir=/usr/sbin \
		--includedir=/usr/include \
		--datadir=/usr/share \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		--localedir=/usr/share/locale \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--sharedstatedir=/var/lib \
		--buildtype=plain \
		--auto-features=auto \
		--wrap-mode=nodownload \
		-Db_lto=true \
		-Db_pie=true \
		-Db_thinlto_cache=true \
		$build_opt || return $?
	meson compile -C _meson_build || return $?
	DESTDIR=$PKG meson install --no-rebuild -C _meson_build || return $?
}

export PATH=$PATH:/sbin:/usr/sbin

if [ "$(id -u)" != 0 ]; then
	echo "run this script as root or use fakeroot"
	exit 1
fi

TOPDIR=$(dirname $(realpath $0))

umask 022

export CWD=$PWD
export name=${CWD##*/}
export PATCH=$CWD/patch
export FILES=$CWD/files

if [ -s ./version ]; then
	export version=$(head -n1 ./version)
else
	export version=1
fi
if [ -s ./release ]; then
	export release=$(head -n1 ./release)
else
	export release=1
fi
if [ -s ./tag ]; then
	export tag=$(head -n1 ./tag)
else
	export tag=any
fi
if [ -s ./source ]; then
	source=$(cat ./source)
fi

PKGTYPE=${PKGTYPE:-txz}
PKGFILE=$name#$version-$release.pkg.tar.xz

while [ $1 ]; do
	case $1 in
		-f) REBUILD=1;;
		-i) INSTALL=1;;
		-u|-r) UPGRADE=1;;
		--root) $pkgadd_opt="-r $2"; ROOT="$2"; shift;;
	esac
	shift
done

if [ -f $TOPDIR/config ]; then
	. $TOPDIR/config
fi

if [ -f $CWD/config ]; then
	. $CWD/config
fi

SOURCEDIR=${SOURCEDIR:-$CWD}
PACKAGEDIR=${PACKAGEDIR:-$CWD}
WORKDIR=${WORKDIR:-$CWD/work}

mkdir -p $SOURCEDIR $PACKAGEDIR

if [ -f "$PACKAGEDIR/$PKGFILE" ] && [ "$REBUILD" != 1 ]; then
	if [ ! "$UPGRADE" ] && [ ! "$INSTALL" ]; then
		echo ":: $PACKAGEDIR/$PKGFILE found"
	fi
else
	# fetch source
	for i in $source; do
		url=${i%::*}
		if [ ! -f $SOURCEDIR/${url##*/} ]; then
			echo "fetching: $url"
			curl -L -C - -o $SOURCEDIR/${url##*/} $url
		fi
	done

	export PKG=$WORKDIR/pkg
	export SRC=$WORKDIR/src

	rm -fr $WORKDIR
	mkdir -p $PKG $SRC

	# prepare source
	for i in $source; do
		url=${i%::*}
		case $i in
			*::noextract) cp $SOURCEDIR/${url##*/} $SRC;;
			*.tar.*|*.tgz) bsdtar xvf $SOURCEDIR/${url##*/} -C $SRC;;
			*) cp $SOURCEDIR/${url##*/} $SRC;;
		esac
	done

	# get dirname
	for i in $source; do
		url=${i%::*}
		case $url in
			*.tar.*|*.tgz) srcdir=$(tar -tf $SOURCEDIR/${url##*/} | cut -d / -f1 | head -n1);;
		esac
		break
	done
	cd $SRC

	if [ "$srcdir" ] && [ -d "$srcdir" ]; then
		cd $srcdir
	fi
	
	if [ ! "$SKIP_PATCH" ]; then
		_auto_patch
	fi

	export DESTDIR=$PKG
	export INSTALLROOT=$PKG  # syslinux
	export install_root=$PKG # glibc
	export INSTALL_ROOT=$PKG # qt5
	
	if [ -f $CWD/build ]; then
		echo ":: running build script: $CWD/build"
		chmod +x $CWD/build
		. $CWD/build || { echo ":: error, build $name failed"; exit 1; }
	else
		echo ":: running auto_build"
		_auto_build || { echo ":: error, build $name failed"; exit 1; }
	fi
	
	if [ -d $PKG/$WORKDIR ]; then
		echo "ERROR: dir '$WORKDIR' inside \$PKG"
		exit 1
	fi
	  
	# Compress manpages and infopages
	if [ -d $PKG/usr/share/man ]; then
		find $PKG/usr/share/man -type f | while read -r file; do
			if [ "$file" = "${file%%.gz}" ]; then
				gzip -9 -f "$file"
			fi
		done
	fi
	if [ -d $PKG/usr/share/info ]; then
		rm -f $PKG/usr/share/info/dir
		find $PKG/usr/share/info -type f | while read -r file; do
			if [ "$file" = "${file%%.gz}" ]; then
				gzip -9 -f "$file"
			fi
		done
	fi
	
	# remove libtool (.la)
	[ "$KEEP_LIBTOOL" = 1 ] || find $PKG ! -type d -name "*.la" -delete
	
	# remove staticlib (.a)
	[ "$KEEP_STATICLIB" = 1  ] || find $PKG ! -type d -name "*.a" -delete

	# remove locales
	[ "$KEEP_LOCALE" = 1  ] || rm -rf $PKG/usr/share/locale
	
	# remove perllocal.pod
	find $PKG ! -type d -name "perllocal.pod" -delete
	
	# remove fonts.scale & fonts.dir
	#find $PKG -name fonts.scale -exec rm {} \;
	find $PKG ! -type d -name "fonts.scale" -delete
	find $PKG ! -type d -name "fonts.dir" -delete

	# strip binaries & libraries
	if [ "$NO_STRIP" != 1  ]; then
		find $PKG -print0 | xargs -0 file | grep -e "executable" -e "shared object" | grep ELF \
		  | cut -f 1 -d : | xargs strip --strip-unneeded 2> /dev/null || true
	fi
	
	# postinstallscript
	if [ -f $CWD/postinstall ]; then
		mkdir -p $PKG/var/lib/pkg/installscripts
		install -m755 $CWD/postinstall $PKG/var/lib/pkg/installscripts/$name
	fi
	
	# runit services
	for i in $CWD/files/*/run; do
		[ -f "$i" ] || continue
		svname=${i%/*}; svname=${svname##*/}
		for f in $CWD/files/$svname/*; do
			file=${f##*/}
			case $file in
				run) install -Dm755 $CWD/files/$svname/$file $PKG/etc/sv/$svname/$file
				     ln -s /run/runit/supervise.$svname $PKG/etc/sv/$svname/supervise;;
				  *) install -Dm644 $CWD/files/$svname/$file $PKG/etc/sv/$svname/$file;;
			esac
		done
	done

	rm -f $PACKAGEDIR/$PKGFILE
	cd $PKG
	echo ":: packaging $PKGFILE..."
	bsdtar --format=gnutar -c -J -f $PACKAGEDIR/$PKGFILE * || {
		echo "error makepkg"
		rm -f $PACKAGEDIR/$PKGFILE
		exit  1
	}
	bsdtar -tvf $PACKAGEDIR/$PKGFILE
	echo ":: package created in $PACKAGEDIR/$PKGFILE"
	cd $CWD
	[ -f .files ] || tar -tvf $PACKAGEDIR/$PKGFILE | awk '{print $1,$2,$6}' > .files
	rm -fr $WORKDIR
fi

if [ "$INSTALL" = 1 ]; then
	[ "$FAKEROOTKEY" ] && { echo ":: cant use fakeroot to install packages"; exit 1; }
	if [ $(pkginfo -i $pkgadd_opt | awk '{print $1}' | grep -x $name) ]; then
		echo "$name is installed already"
		exit 0
	else
		echo ":: installing $PKGFILE..."
		pkgadd $pkgadd_opt $PACKAGEDIR/$PKGFILE
		if [ -x $ROOT/var/lib/pkg/installscripts/$name ]; then
			echo ":: running installscripts for $name" 
			chroot ${ROOT:-/} /var/lib/pkg/installscripts/$name
		fi
		exit 0
	fi
fi
if [ "$UPGRADE" = 1 ]; then
	[ "$FAKEROOTKEY" ] && { echo ":: cant use fakeroot to upgrade packages"; exit 1; }
	if [ ! $(pkginfo -i $pkgadd_opt | awk '{print $1}' | grep -x $name) ]; then
		echo "$name not installed"
		exit 1
	else
		echo ":: upgrading $name-$version-$release..."
		pkgadd $pkgadd_opt -u $PACKAGEDIR/$PKGFILE
		if [ -x $ROOT/var/lib/pkg/installscripts/$name ]; then
			echo ":: running installscripts for $name"
			chroot ${ROOT:-/} /var/lib/pkg/installscripts/$name
		fi
		exit 0
	fi
fi

exit 0	
