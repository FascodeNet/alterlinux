#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#

# Replace wallpaper.
:<<DISABLED
if [[ -f /usr/share/backgrounds/xfce/xfce-stripes.png ]]; then
    remove /usr/share/backgrounds/xfce/xfce-stripes.png
    ln -s /usr/share/backgrounds/alter.png /usr/share/backgrounds/xfce/xfce-stripes.png
fi
[[ -f /usr/share/backgrounds/alter.png ]] && chmod 644 /usr/share/backgrounds/alter.png
DISABLED


# Replace right menu
:<< DISABLED
if [[ "${language}" = "ja" ]]; then
    remove "/etc/skel/.config/Thunar/uca.xml"
    remove "/home/${username}/.config/Thunar/uca.xml"

    mv "/etc/skel/.config/Thunar/uca.xml.jp" "/etc/skel/.config/Thunar/uca.xml"
    mv "/home/${username}/.config/Thunar/uca.xml.jp" "/home/${username}/.config/Thunar/uca.xml"
else
    remove "/etc/skel/.config/Thunar/uca.xml.jp"
    remove "/home/${username}/.config/Thunar/uca.xml.jp"
fi
DISABLED


# Enable LightDM to auto login
if [[ "${boot_splash}" =  true ]]; then
    systemctl enable lightdm-plymouth.service
else
    systemctl enable lightdm.service
fi


# Replace auto login user
sed -i "s|%USERNAME%|${username}|g" "/etc/lightdm/lightdm.conf.d/02-autologin.conf"
