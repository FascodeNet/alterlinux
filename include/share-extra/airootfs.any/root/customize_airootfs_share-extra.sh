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
systemctl enable bluetooth

# Snap
if [[ "${arch}" = "x86_64" ]]; then
    systemctl enable snapd.apparmor.service
    systemctl enable apparmor.service
    systemctl enable snapd.socket
    systemctl enable snapd.service
fi


# firewalld
if installedpkg firewalld; then
    systemctl enable firewalld.service
fi


# Added autologin group to auto login
groupadd autologin
usermod -aG autologin ${username}


# ntp
systemctl enable systemd-timesyncd.service


# Update system datebase
if type -p dconf 1>/dev/null 2>/dev/null; then
    dconf update
fi

