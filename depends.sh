#!/bin/sh

printpkg() {
	grep -qx $1 $INSTALLED && echo "[i] $1" || echo "[-] $1"
}

LIST1=/tmp/$$-list1
INSTALLED=/tmp/$$-installed

if [ "$ROOT" ]; then
	pkginfoopt="-r $ROOT"
fi

# list all installed into file
pkginfo -i $pkginfoopt | awk '{print $1}' > $INSTALLED

for i in $(cat templates/$1/depends); do
	printpkg $i
done
rm -f $LIST1 $INSTALLED
