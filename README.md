# lfs-scripts
Automated script to build LFS system + livecd

## This repo contain scripts to automate LFS build + livecd.

#### Requirements

* sudo
* passed lfs version-check.sh
* squashfs-tools & libisoburn (optiional to create the livecd iso)

#### scripts

* 01-toolchain
  - toolchain script to build base lfs (required)
  - this script need run as regular user
  
* 02-lfs-base
  - script to build base lfs system
  - this script need run as root
  - extra packages is added into this base lfs, ex:
    - dhcpcd
    - wpa_supplicant
    - mkinitramfs (taken from venom linux, livecd support)
    
* 03-mklfsiso
  - script to build lfs livecd iso
  - this script need run as root

#### Note

* If you wanna build lfs to run in your machine/virtual you need to create partition for this lfs system and mount to /mnt/lfs directory.
* If you just wanna create the livecd iso, you can straight run these script without mount partition for lfs.
* By default this script build the lfs system in /mnt/lfs directory, so make sure you spare this directory for it.
