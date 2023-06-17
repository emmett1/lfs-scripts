# lfs-scripts

This repo contain scripts to automate LFS (Linux From Scratch) build, manage, updates, rolling and etc. Yeah its bunch of scripts. Its basically almost whole tools to maintain a Linux distribution. These what I use on my main system as daily use on my main computer. If you want to use LFS as main OS and be able to maintain it, you can use it. But keep in mind, these scripts is not 100% follow LFS, because thats the main point of LFS, you build it yourself and customize it as you want. Your distro your rules, but this one follow my rules.

Heres is important point of `lfs-scripts` that follow my rules;

- bootstrap using [LFS v9.1](https://linuxfromscratch.org/lfs/view/9.1/) way.
- multilib. all 32bit libraries is thrown into `/usr/lib32` directory.
- using part of [CRUX's pkgutils](https://crux.nu/gitweb/?p=tools/pkgutils.git) to track installed packages.
- packages is mostly build automatically using my own build script, and follow pkgutils format (see below how to write package template).
- dependencies handling.
- packages should be build using fakeroot (see below).
- `/usr/libexec/` not use, use `/usr/lib/` instead.
- use `runit` as init by default.
- consolekit2 is used instead of elogind.
- no systemd stuffs.

So there, my rules. If you encounter error or bugs when using `lfs-scripts`, open issue here, dont report to LFS dev, they just gonna ignore you.

# bunch of scripts
So i will explain most of these scripts does, else you have to read on top of each script of what it does and how to use it.

## bootstrap.sh
Like its name, this script is to bootstrap main system of LFS. Theres a few stages to bootsrap base system:
```
1 - build temporary toolchain
2 - build base system (using temporary toolchain)
3 - rebuild base system (without depending on temporary toolchain)
4 - compress base rootfs
```

Stage 1 need to run as regular user to build temporary toolchain. Temporary toolchain is build inside `/tmp` directory so, when reboot, your system might wipe completely the toolchain. But dont worry, at the end of stage 1 the temporary toolchain will get compress as backup incase you wanna reuse it.
```
$ ./bootstrap 1
```

Stage 2 need to run as root to build base LFS system. You can use `sudo` or `doas`. Also, base LFS system is build inside `/tmp` directory, and also, you can compress LFS base system to use it anytime you want without bootstrap again.
```
# ./bootstrap 2
```

Stage 3 also need to run as root to rebuild base system. This stage is completely optional if you wanna skip it. This stage is rebuild base without using temporary toolchain that build on stage 1, but it use its own toolchain instead. Its not in any LFS book but this is my way to make sure my base system is working completely. So if everything is rebuild fine, then i'm assure you that your LFS system is working 100%.
```
# ./bootstrap 3
```

Stage 4 is for compressing your base system into `lfs-rootfs.tar.xz` file, temporary toolchain is excluded. See installing from existing tarball below.
```
$ ./bootstrap 4
```

Okay thats all for bootstrapping LFS base. Just keep `lfs-rootfs.tar.xz` to reuse in the future or share with your friends.

## make.sh
`make.sh` script is a script to automate package build by using package template in `templates` directory. This script need to run as root or using `fakeroot`. Using `fakeroot` is very recommended to make sure no files installed into system untracked. `fakeroot` is part of base system bootstrapped above. But root required to install (`-i`) or upgrade/reinstall (`-u`). `make.sh` available options is:
```
-b         rebuild package
-i         install package into system
-u         upgrade or reinstall package
-f         force install, overwrite conflicting files (passed to pkgadd)
-r <path>  specify alternative installation root (passed to pkgadd)
-c <file>  use alternate configuration file (passed to pkgadd)
```

So basically to use it, first `cd` to package template:
```
$ cd templates/<pkg>
```

then run `make.sh` script using fakeroot by calling full path:
```
$ fakeroot ../../make.sh
```

after package is built, run it again as root using `-i` flag to install or `-u` to upgrade/reinstall:
```
$ sudo ../../make.sh -i
```

Okay it simple as that to get a package installed.

## deplist.sh
This script will solve dependencies and list it in build order. The usage is:
```
$ ./deplist.sh <pkg1> <pkg2> ...
```
excample how to use it:
```
$ ./deplist.sh curl coreutils
[i] openssl
[i] zlib
[i] xz
[i] zstd
[i] curl
[i] attr
[i] acl
[i] gmp
[i] libcap
[i] coreutils
```

Note:

`[i]` means package is installed

`[-]` means package not installed

## pkg.sh
`pkg.sh` script is use to easily installing packages without `cd` into each templates directory and run `fakeroot ../../make.sh` everytime you want to install packages. The usage is:
```
-b         rebuild package
-d         solve dependencies
-f         force install (ignore conflicts)
-h         print help message
-i         install packages
-r <path>  use alternative root location
-c <file>  use alternative pkgadd's configuration files
-y         dont prompt user
```

to install packages with dependencies is by running:
```
$ ./pkg -i -d <pkg1> <pkg2> ...
```

## pkgdiff.sh
`pkgdiff.sh is` a script to show any outdated packages. So basically to check any oudated packages is by running:
```
$ git pull
$ ./pkgdiff.sh
```

## sysup.sh
`sysup.sh` script is for updating installed packages in system with dependency order. Just like `pkgdiff.sh` script, you need to `git pull` first:
```
$ git pull
$ ./sysup.sh
```

## revdep.sh
`revdep .sh` script is important script for source based distros to check any broken library linkage. It will print any broken packages if exist, then you need to rebuild it by using `./pkg.sh -b -u <broken pkgs>`. This script is very recommended to run after packages removal or upgrades. Example output of `revdep.sh` script:
```
$ ./revdep.sh
 anydesk: /usr/lib/anydesk/libgdkglext-x11-1.0.so.0.0.0 (requires libpangox-1.0.so.0)
 anydesk: /usr/lib/anydesk/libgtkglext-x11-1.0.so.0.0.0 (requires libpangox-1.0.so.0)
 firefox-esr: /usr/lib/firefox/libmozavcodec.so (requires libmozavutil.so)
 firefox-esr: /usr/lib/firefox/libxul.so (requires liblgpllibs.so)
 firefox-esr: /usr/lib/firefox/libxul.so (requires libmozgtk.so)
 firefox-esr: /usr/lib/firefox/libxul.so (requires libmozsandbox.so)
 firefox-esr: /usr/lib/firefox/libxul.so (requires libmozsqlite3.so)
 firefox-esr: /usr/lib/firefox/libxul.so (requires libmozwayland.so)
 firefox-esr: /usr/lib/firefox/plugin-container (requires libxul.so)
```
Note: some packages falsely showing broken packages, if after rebuild show same thing, you can ignore it.

## outdate.sh
This script will check package updates from upstream by using `curl -Lsk <url> <any appropriate regex>`. If check fails on default regex, you can specify custom regex in `templates/<pkg>/update` file. See for existing `update` file to write your own. Here example of `update` file for `gtk3` package:
```
port_getver() {
	fetch \
	| tr ' ' '\n' \
	| grep -Eo gtk.-[0-9.]+.tar.[bgx]z2? \
	| sed 's/gtk+-//;s/.tar.*//' \
	| grep -Ew "^[0-9]+\.[0-9]*[02468]\.*" \
	| grep -Ev ".[89][0-9].*"
}
```
to check if its working, run using `-v` option:
```
$ ./outdate.sh -v gtk3
file     : gtk+-3.24.37.tar.xz
filename : gtk+
port     : gtk3
version  : 3.24.37
url      : https://download.gnome.org/sources/gtk+/cache.json
cmd      : port_getver
3.24.29
3.24.30
3.24.31
3.24.32
3.24.33
3.24.34
3.24.35
3.24.36
3.24.37
3.24.38
```
Last version is taken when running without using `-v` option, eg:
```
$ ./outdate.sh gtk3
 gtk3 3.24.38 (3.24.37)
```
then you know theres update from upstream.

run `./outdate.sh` script without any arguments will check all packages in `templates` directory.
```
./outdate.sh
 aaa_filesystem SKIP (20230518)
 acpica-unix 404 (20230331)
 anydesk 404 (6.2.1)
 atkmm 2.36.2 (2.28.3)
 Checking 'audacious'
```

I thinks thats all some explanation for some important scripts, for other scripts you can read explanation on top of the script. Please noted, these scripts might changed from time to time, just keep alert of the changes.

## Configurations
Now i'm gonna explain some other important stuff other than scripts.

# config
edit `config` file follow your need.

# runit
`lfs-scripts` is use `runit` as default init. Basically the initscripts is almost same as the one used in Void Linux, so no need headache to figure out how to use it. I will point some important point of `runit` used:
- theres no runit config file (/etc/runit/rc.conf)
- to enable service, just make symlink from `/etc/sv/<service>` to `/var/service`
- ...

# install to disk
First thing to do is making partition and mount it but i will not teach it here, i assume you already know if you come for LFS stuff. I assume you mount the partition into `/mnt/lfs` directory.

Extract compressed base file system into `/mnt/lfs`
```
# tar -xvf lfs-rootfs.tar.xz -C /mnt/lfs
```

Chroot into new extracted system
```
mount -v --bind /dev /mnt/lfs/dev
mount -vt devpts devpts /mnt/lfs/dev/pts -o gid=5,mode=620
mount -vt proc proc /mnt/lfs/proc
mount -vt sysfs sysfs /mnt/lfs/sys
mount -vt tmpfs tmpfs /mnt/lfs/run
test -h /mnt/lfs/dev/shm && mkdir -pv /mnt/lfs/$(readlink /mnt/lfs/dev/shm)
chroot /mnt/lfs env PS1="(chroot)# " /bin/bash
```

Setting hostname
```
# echo myhostname > /etc/hostname
```

Setting timezone (change XXX and YYY to your choice of timezone)
```
# ln -svf /usr/share/zoneinfo/XXX/YYY /etc/localtime
```

Setting user and password
```
# useradd -m -G users,wheel,audio,video -s /bin/bash <your user>
# passwd <your user>
```

Now we need to switch to created user to build some packages
```
# su - <your user>
```

Alright now we in newly created user. Now clone `lfs-scripts` repo to start build packages (change `<branch>` to correct branch), and configure config file.
```
$ git clone https://github.com/emmett1/lfs-scripts -b <branch> --depth=1
$ cd lfs-scripts
$ vim config
```

Now start build your required packages. 
```
$ ./pkg.sh -i -d runit linux <my needed packages>
```

Thats all, i think you know what to do now like enable some runit service, install grub, install xorg and etc.

#####
NOTE: This documentation still work in progress, more will come.
