#!/bin/bash

passwd -d root &>/dev/null

echo "root:root" | chpasswd -c SHA512

ETHDEV=$(ls /sys/class/net/ | grep -Exv "(lo|sit0)" | head -n1)

if [ "$ETHDEV" ]; then
	cat > /etc/sysconfig/ifconfig.eth0 << EOF
ONBOOT="yes"
IFACE="$ETHDEV"
SERVICE="dhcpcd"
EOF
fi
