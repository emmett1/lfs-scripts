#!/bin/sh

printpkg() {
	grep -qx $1 $INSTALLED && echo "[i] $1 $2" || echo "[-] $1"
}

[ "$1" ] || exit 1

INSTALLED=/tmp/$$-installed

pkginfo -i | awk '{print $1}' > $INSTALLED

for i in templates/*; do
	name=${i#*/}
	case $name in
		*$1*)
		if [ -f $i/version ]; then
			version=$(cat $i/version)
		else
			version=1
		fi
		if [ -f $i/release ]; then
			release=$(cat $i/release)
		else
			release=1
		fi
		printpkg $name $version-$release
	esac
done
rm -f $INSTALLED
