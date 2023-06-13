#!/bin/sh

printpkg() {
	grep -qx $1 $INSTALLED && echo "[i] $1" || echo "[-] $1"
}

checkdep() {
	# track processed pkg to avoid cycle deps
	process="$process $1"
	if [ -f templates/$1/depends ]; then
		for i in $(cat templates/$1/depends); do
			# if deps already in process list, skip, cycle deps detected
			echo $process | grep -qw $i && continue
			# skip if itself in depends list
			[ "$i" = "$1" ] && continue
			# skip if pkg already in deps list
			grep -qx $i $LIST1 && continue
			# check deps
			checkdep $i
		done
	fi
	# will go here if no deps anymore to check, add it to list deps
	echo $1 >> $LIST1
}

run_checkdep() {
	for i in $@; do
		# if already have in list deps, dont check again
		if [ ! $(grep -x $i $LIST1) ]; then
			checkdep $i
		fi
	done
}

LIST1=/tmp/$$-list1
INSTALLED=/tmp/$$-installed

# list all installed into file
pkginfo -i | awk '{print $1}' > $INSTALLED

rm -f $LIST1
touch $LIST1
run_checkdep $@

# cat final list deps
for i in $(cat $LIST1); do
	printpkg $i
done
rm -f $LIST1 $INSTALLED
