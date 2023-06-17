#!/bin/sh

if [ ! "$1" ]; then
	echo "This script will copy template to 32bit template"
	echo
	echo "Usage: $0 <template>"
	exit 1
fi

pkg=$1

if [ ! -d templates/$pkg ]; then
	echo "template '$pkg' not exist"
	exit 1
elif [ -d templates/$pkg-32 ]; then
	echo "template '$pkg' already exist"
	exit 1
else
	cp -r templates/$pkg templates/$pkg-32
	ln -sf ../$pkg/version templates/$pkg-32/version
	ln -sf ../$pkg/source templates/$pkg-32/source
	if [ -f templates/$pkg-32/depends ]; then
		for d in $(cat templates/$pkg-32/depends); do
			echo "$d-32" >> templates/$pkg-32/depends32
		done
		rm templates/$pkg-32/depends
		mv templates/$pkg-32/depends32 templates/$pkg-32/depends
	fi
	echo "template '$pkg-32' created"
fi
