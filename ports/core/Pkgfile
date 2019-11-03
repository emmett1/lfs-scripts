# Description: 
# URL:         
# Maintainer:  
# Depends on:  

name=
version=
release=1
source=()

build() {
	cd $name-$version

	./configure --prefix=/usr
	make
	make DESTDIR=$PKG install
}
