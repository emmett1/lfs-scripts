#!/bin/sh

[ "$1" ] || exit 1

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

[ -d templates/$name ] && {
	echo "template for $name exist"
	exit 1
}

echo "name: $name"
echo "version: $version"

mkdir -p templates/$name

echo $version > templates/$name/version
echo $1 > templates/$name/source
echo 1 > templates/$name/release
leafpad templates/$name/build
leafpad templates/$name/config
