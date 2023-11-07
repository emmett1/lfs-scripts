#!/bin/sh

SEARCH_DIRS="/bin /usr/bin /sbin /usr/sbin /lib /usr/lib /usr/lib32 /usr/libexec"

while read -r line; do
	if [ "$(echo $line | cut -c 1)" = "/" ]; then
		EXTRA_SEARCH_DIRS="$EXTRA_SEARCH_DIRS $line "
	fi
done < /etc/ld.so.conf

if [ -d /etc/ld.so.conf.d/ ]; then
	for dir in $(ls -1 /etc/ld.so.conf.d/*.conf 2>/dev/null); do
		while read -r line; do
			if [ "$(echo $line | cut -c 1)" = "/" ]; then
				EXTRA_SEARCH_DIRS="$EXTRA_SEARCH_DIRS $line "
			fi
		done < $dir
	done
fi

SEARCH_DIRS=$(echo $SEARCH_DIRS $EXTRA_SEARCH_DIRS | tr ' ' '\n' | sort | uniq | tr '\n' ' ')

find $SEARCH_DIRS -type f \( -perm /+u+x -o -name '*.so' -o -name '*.so.*' \) -print 2> /dev/null | sort -u > /tmp/list
total=$(wc -l /tmp/list | awk '{print $1}')
count=0
while read -r line; do
	count=$(( count + 1 ))
	libname=${line##*/}
	printf " $(( 100*count/total ))%% $libname\033[0K\r"
	case "$(file -bi "$line")" in
		*application/x-sharedlib* | *application/x-executable* | *application/x-pie-executable*)
			missinglib=$(ldd /$line 2>/dev/null | grep "not found" | awk '{print $1}' | sort | uniq)
			if [ "$missinglib" ]; then
				for i in $missinglib; do
					objdump -p /$line | grep NEEDED | awk '{print $2}' | grep -qx $i && {
						ownby=$(pkginfo -o $line | tail -n+2 | head -n1 | awk '{print $1}')
						[ "$ownby" ] || continue
						echo " $ownby: $line (requires $i)"
					}
				done
			fi;;
	esac
done < /tmp/list
printf "\033[0K"

rm -f /tmp/list
