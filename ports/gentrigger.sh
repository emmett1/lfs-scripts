#!/bin/sh

g() {
	grep -q $1 $p/.footprint && {
		if [ -f $p/post-install ]; then
			grep -q "$2" $p/post-install && return 0
		fi
		echo "$p: $2"
		echo $2 >> $p/trigger
	}
}

for p in */*/Pkgfile; do
	case $p in
		multilib/*) continue;;
	esac
	p=${p%/*}
	if [ ! -f $p/.footprint ]; then
		echo "$p: .footprint not found"
		continue
	fi
	g usr/share/mime/$ "update-mime-database /usr/share/mime"
	g usr/share/applications/$ "update-desktop-database --quiet"
	g etc/udev/hwdb.d/$ "udevadm hwdb --update"
	g usr/lib/gtk-3.0/3.0.0/immodules/.*.so "gtk-query-immodules-3.0 --update-cache"
	g usr/lib/gtk-2.0/2.10.0/immodules/.*.so "gtk-query-immodules-2.0 --update-cache"
	g usr/share/glib-2.0/schemas/$ "glib-compile-schemas /usr/share/glib-2.0/schemas"
	g usr/lib/gio/modules/.*.so "gio-querymodules /usr/lib/gio/modules"
	g usr/lib/gdk-pixbuf-2.0/2.10.0/loaders/.*.so "gdk-pixbuf-query-loaders --update-cache"
	g usr/share/fonts/$ "fc-cache -s"

	if [ -f $p/trigger ]; then
		echo "#!/bin/sh" > $p/tmppostinstall
		if [ -f $p/post-install ]; then
			grep -Ev ^'#!/bin' $p/post-install >> $p/tmppostinstall
			rm $p/post-install
		fi
		cat $p/trigger >> $p/tmppostinstall
		rm $p/trigger
		mv $p/tmppostinstall $p/post-install
	fi
done
