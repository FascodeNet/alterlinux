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
kernel_config_line='zen linux-zen linux-zen-beaders vmlinuz-linux-zen linux-zen'
theme_name=alter-logo
rebuild=false
username='alter'
os_name="Alter Linux"
install_dir="alter"
usershell="/bin/bash"
debug=false
timezone="UTC"
localegen="en_US\\.UTF-8\\"
language="en"


# Parse arguments
while getopts 'p:bt:k:rxu:o:i:s:da:g:z:l:' arg; do
    case "${arg}" in
        p) password="${OPTARG}" ;;
        b) boot_splash=true ;;
        t) theme_name="${OPTARG}" ;;
        k) kernel_config_line="${OPTARG}" ;;
        r) rebuild=true ;;
        u) username="${OPTARG}" ;;
        o) os_name="${OPTARG}" ;;
        i) install_dir="${OPTARG}" ;;
        s) usershell="${OPTARG}" ;;
        d) debug=true ;;
        x) debug=true; set -xv ;;
        a) arch="${OPTARG}" ;;
        g) localegen="${OPTARG/./\\.}\\" ;;
        z) timezone="${OPTARG}" ;;
        l) language="${OPTARG}" ;;
    esac
done


# Parse kernel
kernel=$(echo ${kernel_config_line} | awk '{print $1}')
kernel_package=$(echo ${kernel_config_line} | awk '{print $2}')
kernel_headers_packages=$(echo ${kernel_config_line} | awk '{print $3}')
kernel_filename=$(echo ${kernel_config_line} | awk '{print $4}')
kernel_mkinitcpio_profile=$(echo ${kernel_config_line} | awk '{print $5}')


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


# Delete icon cache
[[ -f /home/${username}/.cache/icon-cache.kcache ]] && rm /home/${username}/.cache/icon-cache.kcache


if [[ "${arch}" = "x86_64" ]]; then
    # Snap
    systemctl enable snapd.apparmor.service
    systemctl enable apparmor.service
    systemctl enable snapd.socket
    systemctl enable snapd.service


    # firewalld
    systemctl enable firewalld.service
fi


# Disable services.
# To disable start up of sddm.
# If it is enable, Users have to enter password.
#systemctl disable sddm
#if [[ ${boot_splash} = true ]]; then
#    systemctl disable sddm-plymouth.service
#fi


# ntp
systemctl enable systemd-timesyncd.service

