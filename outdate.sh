#!/bin/bash

RED='\e[0;31m'      #Red
GREEN='\e[0;32m'    #Green
YELLOW='\e[0;33m'   #Yellow
CRESET='\e[0m'	    #Reset color

print_progress() {
	echo -ne " $@\033[0K\r"
}

# default getver
getver_default() {
	fetch \
	| grep -Eo $filename[_-][0-9a-z.]+.tar.[bgx]z2? \
	| sed "s/$filename[-_]//;s/\.tar.*//" \
	| grep [[:digit:]] \
	| $grepexclude
}

# per-type getver
getver_github() {
	fetch \
	| grep archive \
	| grep -Eo '(v?|"$filename"-)'[0-9a-z.]+\.tar\.gz \
	| sed "s/\.tar\.gz//;s/^v//;s/^$filename-//" \
	| $grepexclude
}

getver_ruby() {
	fetch \
	| grep -Eo $filename[_-][0-9a-z.]+.gem \
	| sed "s/$filename[-_]//;s/\.gem//" \
	| grep [[:digit:]] \
	| $grepexclude
}

getver_gnome() {
	fetch \
	| tr ' ' '\n' \
	| grep -Eo $filename-[0-9.]+.tar.[bgx]z2? \
	| sed "s/$filename-//;s/\.tar.*//" \
	| grep -Ew "^[0-9]+\.[0-9]*[02468]\.*" \
	| grep -Ev ".[89][0-9].*"
}

getver_gnome2() {
	fetch \
	| tr ' ' '\n' \
	| grep -Eo $filename-[0-9.]+.tar.[bgx]z2? \
	| sed "s/$filename-//;s/\.tar.*//"
}

getver_xfce4() {	
	url=$url/$(fetch \
	| sed 's,.*href=",,;s,\/.*,,' \
	| grep ^[0-9a-z] \
	| grep -E ".*.[02468].*" \
	| sort -V \
	| uniq \
	| tail -n1)	
	getver_default
}

getver_aur() {
	url=https://aur.archlinux.org/packages/$name
	fetch \
	| grep "Package Details:" \
	| cut -d ' ' -f4 \
	| sed 's/-.*//'
}

getver_python() {
	getver_default | grep -v [[:alpha:]]
}

# main
fetch() {
	#wget -qO - -t 3 -T 10 $url
	curl -Lsk $url
}

run_check() {
	checkver_cmd=${1}
	
	if [ "$VERBOSE" = 1 ]; then
		echo "file     : $file"
		echo "filename : $filename"
		echo "port     : $ppath"
		echo "version  : $version"
		echo "url      : $url"
		echo "cmd      : $checkver_cmd"
		$checkver_cmd | sort -V | uniq | tail -n10
	else
		print_progress "Checking '$ppath'"
		upver=$($checkver_cmd | sort -V | uniq | tail -n1)
		echo -ne "\033[0K"

		upver=${upver:-404}
		
		touch $outdateerror $outdatelist
		
		sed "\,^$ppath ,d" -i $outdateerror
		sed "\,^$ppath ,d" -i $outdatelist

		if [ "$upver" = "404" ]; then
			echo -e " $ppath ${RED}404${CRESET} ($version)"
			echo "$ppath $version" >> $outdateerror
		elif [ "$version" != "$upver" ]; then
			echo -e " $ppath ${YELLOW}$upver${CRESET} ($version)"
			echo "$ppath $upver $version" >> $outdatelist
		fi
	fi
}

alter_per_url() {
	case $url in
		*github.com*)
			url=https://github.com/$(echo $url | cut -d / -f4,5)/tags;;
		*downloads.sourceforge.net*)
			url="https://sourceforge.net/projects/$(echo $url | cut -d / -f4)/rss?limit=200";;
		*sourceforge.net*)
			url="https://sourceforge.net/projects/$(echo $url | cut -d / -f5)/rss?limit=200";;
		*gitlab.com*)
			url=$(echo $url | cut -d/ -f1-5)/tags;;
		*python.org*|*pypi.org*|*pythonhosted.org*|*pypi.io*)
			url=https://pypi.org/simple/${name/python?-/};;
		*rubygems.org*)
			url=https://rubygems.org/gems/${name/ruby-/};;
		*launchpad.net*)
			url=https://launchpad.net/$(echo $url | cut -d / -f4)/+download;;
		*ftp.gnome.org*)
			url=https://ftp.gnome.org/pub/gnome/sources/$filename/cache.json;;
		**download.gnome.org**)
			url=https://download.gnome.org/sources/$filename/cache.json;;
		*archive.xfce.org*)
			url=http://archive.xfce.org/src/$(echo $url | cut -d / -f5)/$name/;;
		*pub.mate-desktop.org*)
			url=https://pub.mate-desktop.org/releases/1.26/;;
	esac
}

check() {
	ppath=$1
	
	if [ -f $ppath/source ]; then
		name=$1
		version=$(cat $ppath/version)
		source=$(head -n1 $ppath/source)
	else
		echo "source file for '$1' not found"
		return
	fi
	
	# ignore
	if [ -f "$outdateskip" ]; then
		if grep -qx $ppath "$outdateskip"; then
			echo -e " $ppath ${GREEN}SKIP${CRESET} ($version)"
			return
		fi
	fi

	if [ -z "$source" ]; then
		echo -e " $ppath ${GREEN}SKIP${CRESET} ($version)"
		return
	fi
	
	file=$(basename $(echo $source | awk '{print $1}'))
	ext=$(echo $FILE | sed 's/.*\(\.t.*\).*/\1/')
	#filename=$(basename $file)
	filename=$(echo $file | sed "s/[-_]$version.*//")
	#filename=${filename/-/_}
	#filename=${filename%_*}

	if echo $source | awk '{print $1}' | grep -q "::"; then
		url=$(echo $source | awk '{print $1}' | awk -F '::' '{print $2}')
		url=$(dirname $url)/
	else
		url=$(dirname $(echo $source | awk '{print $1}'))/
	fi

	alter_per_url

	[ "$NOOVERRIDE" ] || {
		[ -f $ppath/update ] && . $ppath/update
	}

	if [ "$(type -t port_getver)" = "function" ]; then
		run_check port_getver
	else
		case $url in
			*github.com*|*gitlab.com*)
				run_check getver_github;;
			*ftp.gnome.org*|*download.gnome.org*)
				run_check getver_gnome;;
			*archive.xfce.org*)
				run_check getver_xfce4;;
			*python.org*|*pypi.org*|*pythonhosted.org*|*pypi.io*)
				run_check getver_python;;
			*rubygems.org*)
				run_check getver_ruby;;
			*kde.org/stable/plasma*|*kde.org/stable/frameworks*|*kde.org/stable/applications*)
				;;
			*)
				run_check getver_default;;
		esac
	fi
	
	unset name version source port_getver url
}

parseopt() {
	while [ $1 ]; do
		case $1 in
			-n) NOOVERRIDE=1;;
			-v) VERBOSE=1;;
			-h) print_help; exit 0;;
			 *) PKG="$PKG $1";;
		esac
		shift
	done
}

print_help() {
	cat << EOF
Script to check port's upstream update

Usage:
  ./$(basename $0) [ options ] [ <pkg1> <pkg2> <pkgN> ]
  
Options:
  -n            dont use update file override
  -v            print port's details
  -h            show this help message
      
EOF
}

main() {
	parseopt $@
	
	cd templates
	
	if [ "$exclude" ]; then
		grepexclude="grep -i -v"
		for i in $exclude; do
			grepexclude="$grepexclude -e $i"
		done
	else
		grepexclude=cat
	fi
	
	if [ "$PKG" ]; then
		for i in $PKG; do
			if [ ! -d $i ]; then
				echo "template '$i' not exist"
				continue
			fi
			check $i
		done
	else
		for i in *; do
			check $i
		done
	fi
}

outdatelist="$PWD/.${0##*/}.list"
outdateerror="$PWD/.${0##*/}.error"
outdateskip="$PWD/.${0##*/}.skip"

exclude="alpha beta doc rc migration example pre dev start cpp data eta release brushes autotools quot* nightly"

#touch $outdatelist $outdateerror $outdateskip
main $@

exit 0
