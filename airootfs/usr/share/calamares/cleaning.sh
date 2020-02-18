#!/usr/bin/env bash

rm -rf /etc/skel/Desktop
rm /etc/systemd/system/getty@tty1.service.d/autologin.conf
rm /root/.automated_script.sh
rm /etc/mkinitcpio-archiso.conf
rm -r /etc/initcpio