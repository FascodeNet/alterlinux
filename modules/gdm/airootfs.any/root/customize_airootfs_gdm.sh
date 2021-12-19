#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#

# Enable gdm to auto login
#if [[ "${boot_splash}" =  true ]]; then
#    _safe_systemctl enable gdm-plymouth.service
#else
    _safe_systemctl enable gdm.service
#fi


# Replace auto login user
sed -i "s/%USERNAME%/${username}/g" "/etc/gdm/custom.conf"


# Remove file for japanese input
if [[ ! "${language}" = "ja" ]]; then
    sed -i "s/export GTK_IM_MODULE=fcitx/#export GTK_IM_MODULE=fcitx/g" "/etc/environment"
    sed -i "s/export QT_IM_MODULE=fcitx/#export QT_IM_MODULE=fcitx/g" "/etc/environment"
    sed -i "s/export XMODIFIERS=@im=fcitx/#export XMODIFIERS=@im=fcitx/g" "/etc/environment"
fi

# Prepare gdm for calamares
for file in "services" "services-plymouth"; do
    if [[ -f "/usr/share/calamares/modules/${file}.conf" ]]; then
        sed -i "s|%DM%|gdm|g" "/usr/share/calamares/modules/${file}.conf"
    fi
done

