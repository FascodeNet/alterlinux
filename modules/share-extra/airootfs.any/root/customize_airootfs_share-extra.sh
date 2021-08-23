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
_safe_systemctl enable bluetooth

# Snap
_safe_systemctl enable snapd.apparmor.service
_safe_systemctl enable apparmor.service
_safe_systemctl enable snapd.socket
_safe_systemctl enable snapd.service
_safe_systemctl enable ufw.service


# Added autologin group to auto login
_groupadd autologin
usermod -aG autologin ${username}


# ntp
_safe_systemctl enable systemd-timesyncd.service


# Update system datebase
if type -p dconf 1>/dev/null 2>/dev/null; then
    dconf update
fi


# Change aurorun files permission
chmod 755 "/home/${username}/.config/autostart/"* "/etc/skel/.config/autostart/"* || true
