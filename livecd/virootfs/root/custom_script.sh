#!/bin/bash

#USER=mylfs
#PASSWORD=mylfs

#useradd -m -G users,wheel,audio,video -s /bin/bash $USER
#passwd -d $USER &>/dev/null
passwd -d root &>/dev/null

echo "root:root" | chpasswd -c SHA512
#echo "$USER:$PASSWORD" | chpasswd -c SHA512

#chmod -R 775 /home/$USER/.config


