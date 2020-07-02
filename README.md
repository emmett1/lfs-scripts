# lfs-scripts

This repo contain scripts to automate multilib LFS build + livecd. This LFS build is using [CRUX](https://crux.nu)'s pkgutils for managing packages and initramfs generator from [Venom Linux](https://venomlinux.org) for livecd initramfs.

#### Requirements

* sudo
* wget
* passes lfs version-check.sh test
* squashfs-tools & libisoburn (optional to create the livecd iso)

#### scripts

* 01-toolchain
  - toolchain script to build base lfs (required)
  - this script need run as regular user
  - this script resume-able, just re-run the script to continue where you left
  
* 02-base
  - script to build base lfs system
  - this script need run as root
  - all package is build using port system (pkgutils)
  - you can create your own ports by follow guide [here](https://crux.nu/Main/Handbook3-5#ntoc23)
  - extra packages is added into this base lfs, eg:
    - linux kernel
    - wget
    - dhcpcd
    - wpa_supplicant
    - mkinitramfs (taken from Venom Linux, livecd support)
    - syslinux
  - this script resume-able, just re-run the script to continue where you left
  - created packages can be reused
    
* 03-mkiso
  - script to build lfs livecd iso
  - this script need run as root
  
* version-check.sh
  - script to check utilities requirements to build lfs
  
#### Step

Basically you just need to run all those 3 scripts without other command to get LFS system built including live ISO. You can run:
```
$ ./01-toolchain && sudo ./02-base && sudo ./03-mkiso
```
*Note: script 01-toolchain gonna ask for sudo password

- First grab any distro's livecd to use as host, or you can just your current running linux distro as host. (read below for tested livecd)
- Prepare your partition for LFS and mount it on `/mnt/lfs` or you can change where LFS build directory in `config` file.
- Optionally modify `config` file to suit your need.
- Run script `01-toolchain` to build temporary toolchain.
- Run script `02-base` to build base LFS system.
- Optionally run script `03-mkiso` to build live iso, then you can test the iso using qemu by running `./run_qemu <iso file>`.
- Run `./enter-chroot` to enter chroot environment to configure your system. [check here](./rootfs/root/README)
- Exit chroot environment.
- Then you should have working LFS system now.
- Reboot to test it out.

#### Host livecd distro

- [Artix Linux](https://artixlinux.org/) - require base-devel and wget
- [Arya Linux](https://aryalinux.info/) (live environment)
- (more will come)
