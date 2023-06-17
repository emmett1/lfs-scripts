#!/bin/sh

pkginfo -i | while read -r iname iversion; do
	irelease=${iversion#*-}
	iversion=${iversion%-*}
	[ -d templates/$iname ] || continue
	if [ -s templates/$iname/version ]; then
		version=$(cat templates/$iname/version)
	else
		version=0
	fi
	if [ -s templates/$iname/release ]; then
		release=$(cat templates/$iname/release)
	else
		release=0
	fi
	if [ "$version" != "$iversion" ] || [ "$release" != "$irelease" ]; then
		echo " $iname $iversion-$irelease => $version-$release"
	fi
done
