#!/usr/bin/env bash

set -e

script_path="$( cd -P "$( dirname "$(readlink -f "${0}")" )" && pwd )"
script_name="$(basename "$(realpath "${0}")")"

function remove () {
    local list
    local file
    list=($(echo "$@"))
    for file in "${list[@]}"; do
        if [[ -f ${file} ]]; then
            rm -f "${file}"
        elif [[ -d ${file} ]]; then
            rm -rf "${file}"
        fi
    done
}

function remove_user_file(){
    remove "/etc/skel/${@}"
    remove "/home/${user}/${@}"
}

while getopts 'u:' arg; do
    case "${arg}" in
        u) user="${OPTARG}";;
    esac
done


# Remove user files
remove /etc/skel/Desktop
remove /usr/share/calamares/
remove_user_file "Desktop/calamares.desktop"
remove_user_file ".config/gtk-3.0/bookmarks"


# Remove polkit role
remove /etc/polkit-1/rules.d/01-nopasswork.rules


# Delete unnecessary files of archiso.
# See the following site for details.
# https://wiki.archlinux.jp/index.php/Archiso#Chroot_.E3.81.A8.E3.83.99.E3.83.BC.E3.82.B9.E3.82.B7.E3.82.B9.E3.83.86.E3.83.A0.E3.81.AE.E8.A8.AD.E5.AE.9A
remove /etc/systemd/system/getty@tty1.service.d/autologin.conf
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
