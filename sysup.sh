#!/bin/sh

echo "Checking outdated packages..."
outdatepkg=$(./pkgdiff.sh | awk '{print $1}' | tr '\n' ' ')

if [ ! "$outdatepkg" ]; then
	echo "No outdated packages"
	exit 0
fi

echo "Sorting package updates order..."
for i in $(./deplist.sh  $outdatepkg | awk '{print $2}'); do
	echo $outdatepkg | grep -qw $i && buildorder="$buildorder $i"
done

echo "Package updates in this order:"
for i in $buildorder; do
	echo " $i"
done
echo
echo "Package updates will process in 3 seconds, Ctrl + C to cancel"
sleep 3

for i in $buildorder; do
	./pkg.sh -u $i
done

exit 0
