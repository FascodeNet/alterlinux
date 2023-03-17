#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#

# Replace wallpaper.
:<< DISABLED
if [[ -d /usr/share/backgrounds/xfce/ ]]; then
    # blaot default
    remove /usr/share/backgrounds/xfce/xfce-*.{jpg,png,svg}

    # replace alter-nochr
    ln -s /usr/share/backgrounds/alter-nochr.png /usr/share/backgrounds/xfce/xfce-verticals.png

    # replace alter
    ln -s /usr/share/backgrounds/alter.png /usr/share/backgrounds/xfce/xfce-stripes.png
    ln -s /usr/share/backgrounds/alter.png /usr/share/backgrounds/xfce/xfce-shapes.svg

    # replace alter-jiju
    ln -s /usr/share/backgrounds/alter-jiju.png /usr/share/backgrounds/xfce/xfce-blue.png
    ln -s /usr/share/backgrounds/alter-jiju.png /usr/share/backgrounds/xfce/xfce-leaves.svg

    # replace alter-old
    ln -s /usr/share/backgrounds/alter-old.png /usr/share/backgrounds/xfce/xfce-teal.png
    ln -s /usr/share/backgrounds/alter-old.png /usr/share/backgrounds/xfce/xfce-flower.svg
fi

    find /usr/share/backgrounds -mindepth 1 -maxdepth 1 -type f -name "alter*" 2> /dev/null | xargs -n1 chmod 644
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
