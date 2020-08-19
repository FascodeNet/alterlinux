#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2020 Fascode Network.
#

set -e -u


# Default value
# All values can be changed by arguments.
password=alter
boot_splash=false
kernel='zen'
theme_name=alter-logo
rebuild=false
japanese=false
username='alter'
os_name="Alter Linux"
install_dir="alter"
usershell="/bin/bash"
debug=true


# Parse arguments
while getopts 'p:bt:k:rxju:o:i:s:da:' arg; do
    case "${arg}" in
        p) password="${OPTARG}" ;;
        b) boot_splash=true ;;
        t) theme_name="${OPTARG}" ;;
        k) kernel="${OPTARG}" ;;
        r) rebuild=true ;;
        j) japanese=true;;
        u) username="${OPTARG}" ;;
        o) os_name="${OPTARG}" ;;
        i) install_dir="${OPTARG}" ;;
        s) usershell="${OPTARG}" ;;
        d) debug=true ;;
        x) debug=true; set -xv ;;
        a) arch="${OPTARG}"
    esac
done


# Delete file only if file exists
# remove <file1> <file2> ...
function remove () {
    local _list
    local _file
    _list=($(echo "$@"))
    for _file in "${_list[@]}"; do
        if [[ -f ${_file} ]]; then
            rm -f "${_file}"
        elif [[ -d ${_file} ]]; then
            rm -rf "${_file}"
        fi
        echo "${_file} was deleted."
    done
}


# Replace wallpaper.
if [[ -f /usr/share/backgrounds/xfce/xfce-stripes.png ]]; then
    remove /usr/share/backgrounds/xfce/xfce-stripes.png
    ln -s /usr/share/backgrounds/alter.png /usr/share/backgrounds/xfce/xfce-stripes.png
fi
[[ -f /usr/share/backgrounds/alter.png ]] && chmod 644 /usr/share/backgrounds/alter.png


# Bluetooth
#rfkill unblock all
#systemctl enable bluetooth

# Replace shortcut list config
if [[ "${japanese}" = true ]]; then
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
    sed -i -e s/chromium/firefox/g /etc/skel/.config/i3/config
    sed -i -e s/chromium/firefox/g /home/${username}/.config/i3/config
fi

# disable light-locker on live
sed -i "/light/s/^/# /g" /home/${username}/.config/i3/config

# Snap
#if [[ "${arch}" = "x86_64" ]]; then
#    systemctl enable snapd.apparmor.service
#    systemctl enable apparmor.service
#    systemctl enable snapd.socket
#    systemctl enable snapd.service
#fi


# Update system datebase
dconf update


# firewalld
#systemctl enable firewalld.service

# ntp
systemctl enable systemd-timesyncd.service


# Added autologin group to auto login
groupadd autologin
usermod -aG autologin ${username}


# Enable LightDM to auto login
if [[ "${boot_splash}" =  true ]]; then
    systemctl enable lightdm-plymouth.service
else
    systemctl enable lightdm.service
fi


# Set script permission
#chmod 755 /usr/bin/alterlinux-gtk-bookmarks

# Replace auto login user
sed -i s/%USERNAME%/${username}/g /etc/lightdm/lightdm.conf
