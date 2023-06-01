#!/bin/sh

printpkg() {
	grep -qx $1 $INSTALLED && echo "[i] $1" || echo "[-] $1"
}

[ "$1" ] || exit 1

INSTALLED=/tmp/$$-installed

pkginfo -i | awk '{print $1}' > $INSTALLED

for i in $(grep $1 templates/*/depends | cut -d / -f2); do
	printpkg $i
done

rm -f $INSTALLED
