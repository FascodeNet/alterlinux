#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#

# Enable LightDM to auto login
if [[ "${boot_splash}" =  true ]]; then
    systemctl enable lightdm-plymouth.service
else
    systemctl enable lightdm.service
fi


# Replace auto login user
sed -i "s|%USERNAME%|${username}|g" "/etc/lightdm/lightdm.conf.d/02-autologin.conf"


# Session list
if [[ -f "/etc/lightdm/lightdm.conf.d/02-autologin-session.conf" ]] && cat "/etc/lightdm/lightdm.conf.d/02-autologin-session.conf" | grep "%SESSION%" 1> /dev/null 2>&1; then
    session_list=()
    while read -r session; do
        session_list+=("${session}")
    done < <(find "/usr/share/xsessions" -type f -print0 -name "*.desktop" | xargs -0 -I{} bash -c 'basename {} | sed "s|.desktop||g"')

    if (( "${#session_list[@]}" == 1)); then
        session="${session_list[*]}"
        sed -i "s|%SESSION%|${session}|g" "/etc/lightdm/lightdm.conf.d/02-autologin-session.conf"
    elif (( "${#session_list[@]}" == 0)); then
        echo "Warining: Auto login session was not found"
    else
        echo "Failed to set the session.Multiple sessions were found." >&2
        echo "Please set the session of automatic login in /etc/lightdm/lightdm.conf.d/02-autologin-session.conf"
        echo "Found session: $(printf "%s " "${session_list[@]}")"
        sleep 0.5
        exit 1
    fi
fi


# For calamares
if [[ -f "/usr/share/calamares/modules/services.conf" ]]; then
    sed -i "s|%DM%|lightdm|g" "/usr/share/calamares/modules/services.conf"
fi
