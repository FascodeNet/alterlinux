#!/usr/bin/env bash

set -e

script_path="$( cd -P "$( dirname "$(readlink -f "${0}")" )" && pwd )"
script_name="$(basename "$(realpath "${script_path}")")"

function remove () {
    rm -rf "${@}"
}

function remove_user_file(){
    remove "/etc/skel/${*}"
    remove "/home/${user}/${*}"
}

while getopts 'u:' arg; do
    case "${arg}" in
        u) user="${OPTARG}";;
        *) return 1;
    esac
done


# Remove user files
remove /etc/skel/Desktop
remove /usr/share/calamares/
remove_user_file "Desktop/calamares.desktop"
remove_user_file ".config/gtk-3.0/bookmarks"


# Remove polkit role
remove /etc/polkit-1/rules.d/01-nopasswork.rules

remove /etc/systemd/system/getty@.service.d/autologin.conf
remove /root/.automated_script.sh
remove /etc/mkinitcpio-archiso.conf
remove /etc/initcpio
remove /boot/archiso.img
remove /etc/systemd/system/etc-pacman.d-gnupg.mount
remove /etc/systemd/journald.conf.d/volatile-storage.conf
remove /airootfs.any/etc/systemd/logind.conf.d/do-not-suspend.conf


# Disabled auto login
if [[ -f "/etc/gdm/custom.conf" ]]; then
    sed -i "s/Automatic*/#Automatic/g" "/etc/gdm/custom.conf"
fi
if [[ -f "/etc/lightdm/lightdm.conf" ]]; then
    sed -i "s/^autologin/#autologin/g" "/etc/lightdm/lightdm.conf"
fi


# Remove dconf for live environment
remove "/etc/dconf/db/local.d/02-live-"*


# Update system datebase
dconf update

# 追加のスクリプトを実行
if [[ -d "${script_path}/${script_name}.d/" ]]; then
    for extra_script in "${script_path}/${script_name}.d/"*; do
        bash -c "${extra_script} ${user}"
    done
fi
