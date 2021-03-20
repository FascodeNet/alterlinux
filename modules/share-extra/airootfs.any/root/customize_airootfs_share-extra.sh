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


# Pipewire
# Do not use _systemd_service because pipewire services are not system but user
# Use flag "--user --global"
# https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/923
for _service in "pipewire.service" "pipewire-pulse.service"
    if systemctl --user --global cat "${_service}" 1> /dev/null 2>&1; then
        systemctl --user --global enable "${_service}"
    fi
done


# Update system datebase
if type -p dconf 1>/dev/null 2>/dev/null; then
    dconf update
fi

