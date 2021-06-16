#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#

# Delete icon cache
remove "/home/${username}/.cache/icon-cache.kcache"

# Delete config file to disable free space notification only for live
remove "/etc/skel/.config/plasmanotifyrc"

if [[ "${arch}" = "x86_64" ]]; then
    # Snap
    systemctl enable snapd.apparmor.service
    systemctl enable apparmor.service
    systemctl enable snapd.socket
    systemctl enable snapd.service
fi


# Bluetooth
rfkill unblock all
systemctl enable bluetooth

# Update system datebase
dconf update

# Enable SDDM to auto login in live session
if [[ "${boot_splash}" = true ]]; then
    systemctl enable sddm-plymouth.service
    systemctl disable sddm.service
else
    systemctl enable sddm.service
fi

echo -e "\nremove /etc/sddm.conf.d/autologin.conf" >> "/usr/share/calamares/final-process"
sed -i "s|%USERNAME%|${username}|g" "/etc/sddm.conf.d/autologin.conf"


# ntp
systemctl enable systemd-timesyncd.service
