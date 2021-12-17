#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#

# Replace shortcut list config
if [[ "${language}" = "ja" ]]; then
    remove "/etc/skel/.config/conky/conky.conf"
    mv "/etc/skel/.config/conky/conky-jp.conf" "/etc/skel/.config/conky/conky.conf"

    remove "/home/${username}/.config/conky/conky.conf"
    remove "/home/${username}/.config/conky/conky-live.conf"
    mv "/home/${username}/.config/conky/conky-live-jp.conf" "/home/${username}/.config/conky/conky.conf"
else
    remove "/etc/skel/.config/conky/conky-jp.conf"

    remove "/home/${username}/.config/conky/conky-jp.conf"
    remove "/home/${username}/.config/conky/conky-live-jp.conf"
    mv "/home/${username}/.config/conky/conky-live.conf" "/home/${username}/.config/conky/conky.conf"
fi
remove "/etc/skel/.config/conky/conky-live.conf"
remove "/etc/skel/.config/conky/conky-live-jp.conf"
remove "/home/${username}/.config/conky/conky-jp.conf"

# Change browser that open help file
if [[ "${arch}" = "i686" ]]; then
    sed -i -e s/chromium/firefox/g "/etc/skel/.config/i3/config"
    sed -i -e s/chromium/firefox/g "/home/${username}/.config/i3/config"
fi

# disable light-locker on live
sed -i "/light/s/^/# /g" "/home/${username}/.config/i3/config"

# disable auto screen lock
rm /etc/xdg/autostart/light-locker.desktop

# Update system datebase
dconf update

# ntp
systemctl enable systemd-timesyncd.service

# Enable LightDM to auto login
if [[ "${boot_splash}" =  true ]]; then
    systemctl enable lightdm-plymouth.service
else
    systemctl enable lightdm.service
fi

# Replace auto login user
sed -i "s|%USERNAME%|${username}|g" "/etc/lightdm/lightdm.conf.d/02-autologin.conf"
