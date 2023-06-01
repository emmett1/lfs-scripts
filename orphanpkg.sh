#!/bin/sh

LIST1=/tmp/$$-list1
INSTALLED=/tmp/$$-installed

pkginfo -i | awk '{print $1}' > $INSTALLED
for i in $(cat $INSTALLED); do
	[ -f templates/$i/depends ] || continue
	cat templates/$i/depends >> $LIST1
done

cat $LIST1 | sort -u > $LIST1
grep -Fxv -f $LIST1 $INSTALLED
