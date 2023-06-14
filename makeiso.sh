#!/bin/sh -e

ROOT=/tmp/lfs-rootfs
LIVE=/tmp/lfs-live
OUTPUT=$PWD/linuxfromscratch.iso
LABEL=LFS_LIVE

# load loop module first, no point going further if cant load loop module
modprobe loop || {
	echo "failed load 'loop' module"
	exit 1
}

rm -fr $LIVE $ROOT
mkdir -p $LIVE $ROOT/var/lib/pkg
touch $ROOT/var/lib/pkg/db

# install base packages
./pkg.sh -r $ROOT -y -i $(cat baselist | tr '\n' ' ')

# required packages
./pkg.sh -r $ROOT -y -i -d linux-lts linux-firmware squashfs-tools syslinux grub-efi runit-rc

# custom packages
./pkg.sh -r $ROOT -y -i -d xorg-server xinit openbox tint2 picom obmenu-generator networkmanager pcmanfm gvfs \
	firefox-esr slim polkit-gnome lxappearance-obconf

mkdir -p $LIVE/boot
mkdir -p $LIVE/isolinux
mkdir -p $LIVE/rootfs

#if [ -d rootfs ]; then
	#cp -ra rootfs/* $LIVE/rootfs/
	#chown -R 0:0 $LIVE/rootfs
#fi

for i in isolinux.bin chain.c32 ldlinux.c32 libutil.c32 libcom32.c32 \
	vesamenu.c32 menu.c32 reboot.c32 poweroff.c32; do
	cp $ROOT/usr/share/syslinux/$i $LIVE/isolinux
done

if [ -f rootfs.sfs ]; then
	cp rootfs.sfs $LIVE/boot/
else
	mksquashfs $ROOT $LIVE/boot/rootfs.sfs \
			-b 1048576 \
			-comp xz \
			-e $ROOT/root/* \
			-e $ROOT/home/* \
			-e $ROOT/tools* \
			-e $ROOT/tmp/* \
			-e $ROOT/dev/* \
			-e $ROOT/proc/* \
			-e $ROOT/sys/* \
			-e $ROOT/run/* 2>/dev/null
fi

KERNELVER=$(file $ROOT/boot/vmlinuz-linux | awk '{print $9}')
sed "s/LIVEISO/$LABEL/g" $ROOT/usr/share/mkinitramfs/hooks/liveiso.hook > $ROOT/etc/mkinitramfs.d/lfsliveiso.hook
chroot $ROOT mkinitramfs -k $KERNELVER -a lfsliveiso -o /boot/initrd-linux.img
rm -f $ROOT/etc/mkinitramfs.d/lfsliveiso.hook
cp $ROOT/boot/vmlinuz-linux $LIVE/boot/vmlinuz
mv $ROOT/boot/initrd-linux.img $LIVE/boot/initrd

mkdir -p $LIVE/boot/grub/x86_64-efi $LIVE/boot/grub/fonts
echo "set prefix=/boot/grub" > $LIVE/boot/grub-early.cfg
cp -a $ROOT/usr/lib/grub/x86_64-efi/*.mod $LIVE/boot/grub/x86_64-efi
cp -a $ROOT/usr/lib/grub/x86_64-efi/*.lst $LIVE/boot/grub/x86_64-efi
cp $ROOT/usr/share/grub/unicode.pf2 $LIVE/boot/grub/fonts/

rm -f $LIVE/boot/efiboot.img
mkdir -p $LIVE/efi/boot
grub-mkimage -c $LIVE/boot/grub-early.cfg -o $LIVE/efi/boot/bootx64.efi -O x86_64-efi -p "" iso9660 normal search search_fs_file
dd if=/dev/zero of=$LIVE/boot/efiboot.img count=4096
mkdosfs -n LIVE-UEFI $LIVE/boot/efiboot.img
mkdir -p $LIVE/boot/efiboot
mount -o loop $LIVE/boot/efiboot.img $LIVE/boot/efiboot
mkdir -p $LIVE/boot/efiboot/EFI/boot
cp $LIVE/efi/boot/bootx64.efi $LIVE/boot/efiboot/EFI/boot
umount $LIVE/boot/efiboot
rm -fr $LIVE/boot/efiboot

echo "set default=0
set timeout=10

insmod all_video
insmod gfxterm
terminal_output gfxterm
loadfont /boot/grub/fonts/unicode.pf2
insmod gfxterm_background
insmod png
background_image /isolinux/splash.png

set color_normal=light-gray/black
set color_highlight=white/black

menuentry 'Linux From Scratch (UEFI mode)' {
    linux /boot/vmlinuz ro quiet
    initrd /boot/initrd
}
menuentry 'Linux From Scratch (UEFI mode) debug' {
    linux /boot/vmlinuz ro verbose
    initrd /boot/initrd
}
menuentry 'Linux From Scratch (UEFI mode) [Ram]' {
    linux /boot/vmlinuz ro quiet ram
    initrd /boot/initrd
}
menuentry 'Linux From Scratch (UEFI mode) [Ram] debug' {
    linux /boot/vmlinuz ro verbose ram
    initrd /boot/initrd
}
menuentry 'Reboot' {
	reboot
}
menuentry 'Poweroff' {
	halt
}" > $LIVE/boot/grub/grub.cfg

echo "UI /isolinux/vesamenu.c32
DEFAULT silent
TIMEOUT 100
#MENU RESOLUTION 1024 768

MENU VSHIFT 2
MENU ROWS 7

# Refer to http://syslinux.zytor.com/wiki/index.php/Doc/menu
MENU BACKGROUND splash.png
MENU COLOR border       * #00000000 #00000000 none
MENU COLOR title        * #90ffffff #00000000 std
MENU COLOR sel          * #e0ffffff #20ffffff all
MENU COLOR unsel        * #50ffffff #00000000 std
MENU color timeout	* #c0ffffff #00000000 std
MENU color help         * #c0ffffff #00000000 std
MENU color msg07        * #c0ffffff #00000000 std

MENU TABMSG Press ENTER to boot or TAB to edit a menu entry
MENU AUTOBOOT BIOS default device boot in # second{,s}...

MENU TIMEOUTROW -4
MENU TABMSGROW -1
MENU CMDLINEROW -1

LABEL silent
MENU LABEL Linux From Scratch
KERNEL /boot/vmlinuz
APPEND initrd=/boot/initrd quiet

LABEL debug
MENU LABEL Linux From Scratch (Debug)
KERNEL /boot/vmlinuz
APPEND initrd=/boot/initrd verbose

LABEL silentram
MENU LABEL Linux From Scratch [Ram]
KERNEL /boot/vmlinuz
APPEND initrd=/boot/initrd quiet ram

LABEL debugram
MENU LABEL Linux From Scratch [Ram] (Debug)
KERNEL /boot/vmlinuz
APPEND initrd=/boot/initrd verbose ram

LABEL existing
MENU LABEL Boot existing OS
COM32 chain.c32
APPEND hd0 0

LABEL reboot
MENU LABEL Reboot
COM32 reboot.c32

LABEL poweroff
MENU LABEL Poweroff
COM32 poweroff.c32
" > $LIVE/isolinux/isolinux.cfg

rm -f $OUTPUT
xorriso -as mkisofs \
	-isohybrid-mbr $ROOT/usr/share/syslinux/isohdpfx.bin \
	-c isolinux/boot.cat \
	-b isolinux/isolinux.bin \
	  -no-emul-boot \
	  -boot-load-size 4 \
	  -boot-info-table \
	-eltorito-alt-boot \
	-e boot/efiboot.img \
	  -no-emul-boot \
	  -isohybrid-gpt-basdat \
	  -volid $LABEL \
	-o $OUTPUT $LIVE
