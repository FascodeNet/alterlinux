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


# Bluetooth
rfkill unblock all
systemctl enable bluetooth


# Replace panel config
if [[ "${japanese}" = true ]]; then
    remove "/etc/skel/.config/lxpanel/LXDE/panels/panel"
    mv "/etc/skel/.config/lxpanel/LXDE/panels/panel-jp" "/etc/skel/.config/lxpanel/LXDE/panels/panel"

    remove "/home/${username}/.config/lxpanel/LXDE/panels/panel"
    mv "/home/${username}/.config/lxpanel/LXDE/panels/panel-jp" "/home/${username}/.config/lxpanel/LXDE/panels/panel"
else
    remove "/etc/skel/.config/lxpanel/LXDE/panels/panel-jp"
    remove "/home/${username}/.config/lxpanel/LXDE/panels/panel-jp"
fi


# Update system datebase
dconf update


# Snap
systemctl enable snapd.apparmor.service
systemctl enable apparmor.service
systemctl enable snapd.socket
systemctl enable snapd.service


# firewalld
systemctl enable firewalld.service


# Replace link
if [[ "${japanese}" = true ]]; then
    remove /etc/skel/Desktop/welcome-to-alter.desktop
    remove /home/${username}/Desktop/welcome-to-alter.desktop

    mv /etc/skel/Desktop/welcome-to-alter-jp.desktop /etc/skel/Desktop/welcome-to-alter.desktop
    mv /home/${username}/Desktop/welcome-to-alter-jp.desktop /home/${username}/Desktop/welcome-to-alter.desktop
else
    remove /etc/skel/Desktop/welcome-to-alter-jp.desktop
    remove /home/${username}/Desktop/welcome-to-alter-jp.desktop
fi