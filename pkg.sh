#!/bin/sh -e

printhelp() {
	cat << EOF
Usage:
  $0 <options> <pkgs>
	
Options:
  -b         rebuild package
  -d         solve dependencies
  -f         force install (ignore conflicts)
  -h         print help message
  -i         install packages
  -r <path>  use alternative root location
  -c <file>  use alternative pkgadd's configuration files
  -y         dont prompt user
EOF
exit 0
}

cd $(dirname $0)

if [ -f ./config ]; then
	. ./config
fi

[ -f /usr/bin/fakeroot ] && FAKEROOT=fakeroot
[ -f /usr/bin/sudo ] && SUDO=sudo

while [ $1 ]; do
	case $1 in
		-h) printhelp;;
		-y) noprompt=1;;
		-d) deps=1;;
		-b) rebuild="$1";;
		-i) install=1;;
		-u) upgrade=1;;
		-f) _opt="$_opt $1";;
		-r) _opt="$1 $2"; ROOT=$2; shift;;
		-c) _opt="$1 $2"; shift;;
		 *) _pkg="$_pkg $1";;
	esac
	shift
done

# solve dependencies if '-d' is used
if [ "$deps" ]; then
	if [ ! "$install" ]; then
		echo "'-d' option need to use with '-i' option"
		exit 1
	fi
	_pkg=$(ROOT=$ROOT ./deplist.sh $_pkg | grep '\[-\]' | awk '{print $2}' | tr '\n' ' ')
fi

if [ ! "$_pkg" ]; then
	echo "nothing will be installed"
	exit 0
else
	for i in $_pkg; do
		[ -d templates/$i ] || missingtemplates="$missingtemplates $i"
	done
	if [ "$missingtemplates" ]; then
		echo "these templates not exist:"
		for i in $missingtemplates; do
			echo " $i"
		done
		exit 1
	fi
	# without '-i' option, only build, no need to prompt user
	if [ "$install" ] && [ ! "$noprompt" ]; then
		echo "these packages will be installed:"
		for i in $_pkg; do
			echo " $i"
		done
		echo
		echo -n "Enter to continue installation, Ctrl + c to cancel " 
		read -r option
	fi
fi

for p in $_pkg; do
	if [ ! -d templates/$p ]; then
		echo "template '$p' not exist"
	else
		TMPPWD=$PWD
		cd templates/$p
		$FAKEROOT ../../make.sh $rebuild
		if [ "$install" ]; then
			$SUDO ../../make.sh -i $_opt
		elif [ "$upgrade" ]; then
			$SUDO ../../make.sh -u $_opt
		fi
		cd $TMPPWD
	fi
done

exit 0
