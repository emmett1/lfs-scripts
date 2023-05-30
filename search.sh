#!/bin/sh

[ "$1" ] || exit 1

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
		pkginfo -i | awk '{print $1}' | grep -qx $name && {
			echo "[i] $name $version $release"
		} || {
			echo "[-] $name $version $release"
		}
	esac
done
