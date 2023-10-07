#!/bin/sh

LIST1=/tmp/$$-list1
LIST2=/tmp/$$-list2

pkginfo -i | awk '{print $1}' | grep -qx $1 || {
	echo "$1 not installed"
	exit 1
}

touch $LIST1
pkginfo -l $1 | grep -E ^'(usr/bin/|usr/sbin/|bin/|sbin/|lib/|usr/lib/|usr/lib32/)' | while read -r line; do
	case "$(file -bi /$line)" in
		*application/x-sharedlib* | *application/x-executable* | *application/x-pie-executable*)
			for NEEDED in $(objdump -x /$line | grep NEEDED | awk '{print $2}'); do
				case $NEEDED in
					libc.so.6|ld-linux.so.2|ld-linux-x86-64.so.2) continue;;
				esac
				libpath=$(ldd /$line 2>/dev/null | awk '{print $3}' | grep $NEEDED)
				[ "$libpath" ] || continue
				libpath=$(realpath $libpath)
				grep -qx $libpath $LIST1 || echo $libpath >> $LIST1
			done
	esac
done
touch $LIST2
for i in $(cat $LIST1); do
	pkginfo -o $i$ | tail -n+2 | head -n1 | awk '{print $1}' >> $LIST2
done
sed "/$1/d;/glibc/d;/gcc/d;/binutils/d" -i $LIST2
cat $LIST2 | sort -u
rm -f $LIST1 $LIST2
