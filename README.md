# lfs-scripts

This repo contain scripts to automate LFS build + livecd.

#### Requirements

* sudo
* passes lfs version-check.sh test
* squashfs-tools & libisoburn (optional to create the livecd iso)

#### scripts

* 01-toolchain
  - toolchain script to build base lfs (required)
  - this script need run as regular user
  - this script resume-able, just re-run the script to continue where you left
  
* 02-lfs-base
  - script to build base lfs system
  - this script need run as root
  - each package has its own build script
  - you can create your own package build scripts using template (in lfs/pkgscripts dir)
  - extra packages is added into this base lfs, eg:
    - linux kernel
    - wget
    - dhcpcd
    - wpa_supplicant
    - mkinitramfs (taken from Venom Linux, livecd support)
  - this script resume-able, just re-run the script to continue where you left
    
* 03-mklfsiso
  - script to build lfs livecd iso
  - this script need run as root
  
* version-check.sh
  - script to check utilities requirements to build lfs

#### Note

* If you wanna build lfs to run in your machine/virtual you need to create partition for this lfs system and mount to /mnt/lfs directory.
* If you just wanna create the livecd iso, you can straight run these script without mount partition for lfs.
* By default this script build the lfs system in /mnt/lfs directory, so make sure you spare this directory for it.
* If you wanna include extra package to base system/livecd, create build script into lfs/pkgscripts directory using existing template, edit 02-lfs-base script, add your custom package name to 'EXTRA_PKGS' and re-run the script.
* By default all package built using '-O2 -march=x86-64 -pipe' for CFLAGS and CXXFLAGS, all cores for 'MAKEFLAGS', edit lfs/pkg.conf if you wanna change it.
