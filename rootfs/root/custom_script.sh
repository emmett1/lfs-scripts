#!/bin/bash

passwd -d root &>/dev/null

echo "root:root" | chpasswd -c SHA512
