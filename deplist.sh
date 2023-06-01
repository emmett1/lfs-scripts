#!/bin/sh

printpkg() {
	grep -qx $1 $INSTALLED && echo "[i] $1" || echo "[-] $1"
}

checkdep() {
	[ -f templates/$1/depends ] || return
	for i in $(cat templates/$1/depends); do
		[ "$i" = "$1" ] && continue
		grep -qx $i $LIST1 && continue
		#echo $i
		echo $i >> $LIST1
		checkdep $i
	done
}

run_checkdep() {
	for i in $@; do
		grep -qx $i $LIST1 || {
			#echo $i
			echo $i >> $LIST1
		}
		checkdep $i
	done
}

LIST1=/tmp/$$-list1
INSTALLED=/tmp/$$-installed

pkginfo -i | awk '{print $1}' > $INSTALLED

rm -f $LIST1
touch $LIST1
run_checkdep $@
for i in $(tac $LIST1); do
	printpkg $i
done
rm -f $LIST1 $INSTALLED
