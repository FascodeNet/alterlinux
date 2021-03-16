#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#

# Bluetooth
rfkill unblock all
_systemd_service enable bluetooth

# Snap
_systemd_service enable snapd.apparmor.service
_systemd_service enable apparmor.service
_systemd_service enable snapd.socket
_systemd_service enable snapd.service


# firewalld
_systemd_service enable firewalld.service


# Added autologin group to auto login
groupadd autologin
usermod -aG autologin ${username}


# ntp
_systemd_service enable systemd-timesyncd.service


# Update system datebase
if type -p dconf 1>/dev/null 2>/dev/null; then
    dconf update
fi

