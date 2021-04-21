#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#

# Enable gdm to auto login
if [[ "${boot_splash}" =  true ]]; then
    systemctl enable gdm-plymouth.service
else
    systemctl enable gdm.service
fi


# Replace auto login user
sed -i "s/%USERNAME%/${username}/g" "/etc/gdm/custom.conf"


# Remove file for japanese input
if [[ ! "${language}" = "ja" ]]; then
    sed -i "s/export GTK_IM_MODULE=fcitx/#export GTK_IM_MODULE=fcitx/g" "/etc/environment"
    sed -i "s/export QT_IM_MODULE=fcitx/#export QT_IM_MODULE=fcitx/g" "/etc/environment"
    sed -i "s/export XMODIFIERS=@im=fcitx/#export XMODIFIERS=@im=fcitx/g" "/etc/environment"
fi
