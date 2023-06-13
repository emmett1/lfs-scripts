#!/bin/sh

pkginfo -i | while read -r iname iversion; do
	irelease=${iversion#*-}
	iversion=${iversion%-*}
	#echo ":: $iname - $iversion - $irelease"
	[ -d templates/$iname ] || continue
	version=$(cat templates/$iname/version)
	release=$(cat templates/$iname/release)
	#echo $iname $version $iversion
	if [ "$version" != "$iversion" ]; then
		echo " $iname $iversion => $version"
	fi
done
