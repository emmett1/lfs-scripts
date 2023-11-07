#!/bin/sh

run() {
	command -v $1 >/dev/null && $@
}

run update-desktop-database --quiet
run update-mime-database /usr/share/mime
run udevadm hwdb --update
run gtk-query-immodules-3.0 --update-cache
run gtk-query-immodules-2.0 --update-cache
run glib-compile-schemas /usr/share/glib-2.0/schemas
run gio-querymodules /usr/lib/gio/modules
run gdk-pixbuf-query-loaders --update-cache
run fc-cache -s

command -v gtk-update-icon-cache >/dev/null && {
	for dir in /usr/share/icons/* ; do
		if [ -e $dir/index.theme ]; then
			gtk-update-icon-cache -q $dir 2>/dev/null
		else
			rm -f $dir/icon-theme.cache
			rmdir --ignore-fail-on-non-empty $dir
		fi
	done
}

command -v mkfontdir >/dev/null && {
	for dir in $(find /usr/share/fonts -maxdepth 1 -type d \( ! -path /usr/share/fonts \)); do
		rm -f $dir/fonts.scale $dir/fonts.dir $dir/.uuid
		rmdir --ignore-fail-on-non-empty $dir
		[ -d "$dir" ] || continue
		mkfontdir $dir
		mkfontscale $dir
	done
}

