#!/bin/sh

[ "$1" ] || exit 1

#if [ ! -f REPO ]; then
	#echo "you not inside repo's directory"
	#exit 1
#fi

name=$(echo $1 | rev | cut -d / -f1 | cut -d - -f2- | rev | tr '[:upper:]' '[:lower:]')
version=$(echo $1 | rev | cut -d / -f1 | cut -d - -f1 | rev | sed 's/\.tar.*//')

case $1 in
	*.pythonhosted.*) name="python3-$name";;
	*.metacpan.*|*.cpan.*) name="perl-$name";;
	*) name=$name;;
esac

if [ "$2" ]; then
	name=$2
fi

[ -d $name ] && {
	grep ^version= $name/Pkgfile
	echo "port for $name exist"
	exit 1
}
url=$(echo $1 | sed "s,$name,\${name},g;s,$version,\${version},g" )

case $version in
	*.*.*) v=${version%.*}
		url=$(echo $url | sed "s,$v,\${version%\.\*},g" )
esac

#echo "name: $name"
#echo "version: $version"
mkdir -p $name

echo "# Depends on: 

name=$name
version=$version
release=1
source=($url)" > $name/Pkgfile

cat $name/Pkgfile
