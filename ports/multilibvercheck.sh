#!/bin/bash

for i in multilib/*-32; do
	p=${i%-32}
	p=${p#*/}
	. $i/Pkgfile
	mv=$version
	for r in core extra; do
		if [ -d $r/$p ]; then
			. $r/$p/Pkgfile
			[ "$version" != "$mv" ] && echo "$name-32 $mv -> $version"
		fi
	done
done
