#!/bin/sh -e

if [ -f ./config ]; then
	. ./config
fi

while [ $1 ]; do
	case $1 in
		-f) rebuild="$1";;
		-r|-u) reinstall=1;;
		-i) install=1;;
		--root) _opt="$1 $2"; shift;;
		*) _pkg="$_pkg $1";;
	esac
	shift
done

for p in $_pkg; do
	if [ ! -d templates/$p ]; then
		echo "'$p' not exist"
	else
		cd templates/$p
		fakeroot ../../make.sh $rebuild
		if [ "$reinstall" ]; then
			sudo ../../make.sh -u $_opt || sudo ../../make.sh -r $_opt
		elif [ "$install" ]; then
			sudo ../../make.sh -i $_opt
		fi
		cd - >/dev/null 2>&1
	fi
done

exit 0
