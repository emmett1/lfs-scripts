#!/bin/sh

g() {
	grep -q $1 $port/.footprint && {
		if [ -f $port/post-install ]; then
			grep -q "$2" $port/post-install && return 0
		fi			
		echo $2 >> $port/trigger
	}
}

if [ ! -f $1/.footprint ]; then
	echo "$1: footprint not found"
	exit 1
fi

port=$1

g usr/share/mime/$ "update-mime-database /usr/share/mime"
g usr/share/applications/$ "update-desktop-database --quiet"
#g usr/share/fonts/$ font
g etc/udev/hwdb.d/$ "udevadm hwdb --update"
#g usr/share/icons/$ icon
g usr/lib/gtk-3.0/3.0.0/immodules/.*.so "gtk-query-immodules-3.0 --update-cache"
g usr/lib/gtk-2.0/2.10.0/immodules/.*.so "gtk-query-immodules-2.0 --update-cache"
g usr/share/glib-2.0/schemas/$ "glib-compile-schemas /usr/share/glib-2.0/schemas"
g usr/lib/gio/modules/.*.so "gio-querymodules /usr/lib/gio/modules"
g usr/lib/gdk-pixbuf-2.0/2.10.0/loaders/.*.so "gdk-pixbuf-query-loaders --update-cache"
g usr/share/fonts/$ "fc-cache -s"

if [ -f $port/trigger ]; then
	echo "#!/bin/sh" > $port/tmppostinstall
	if [ -f $port/post-install ]; then
		grep -Ev ^'#!/bin' $port/post-install >> $port/tmppostinstall
		rm $port/post-install
	fi
	cat $port/trigger >> $port/tmppostinstall
	rm $port/trigger
	mv $port/tmppostinstall $port/post-install
fi
		
