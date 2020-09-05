#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascone.net
#
# (c) 2019-2020 Fascode Network.
#

set -e -u


# Default value
# All values can be changed by arguments.
password=alter
boot_splash=false
kernel_config_line=("zen" "linux-zen" "linux-zen-beaders" "vmlinuz-linux-zen" "linux-zen")
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
        k) kernel_config_line=(${OPTARG}) ;;
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
kernel="${kernel_config_line[0]}"
kernel_package="${kernel_config_line[1]}"
kernel_headers_packages="${kernel_config_line[2]}"
kernel_filename="${kernel_config_line[3]}"
kernel_mkinitcpio_profile="${kernel_config_line[4]}"


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
if [[ -f /usr/share/backgrounds/deepin/desktop.jpg ]]; then
    remove /usr/share/backgrounds/deepin/desktop.jpg
    ln -s /usr/share/backgrounds/alter.png /usr/share/backgrounds/deepin/desktop.jpg
fi
[[ -f /usr/share/backgrounds/alter.png ]] && chmod 644 /usr/share/backgrounds/alter.png


# Bluetooth
rfkill unblock all
systemctl enable bluetooth


# Update system datebase
dconf update

# Added autologin group to auto login
groupadd autologin
usermod -aG autologin ${username}


# Enable LightDM to auto login
if [[ "${boot_splash}" =  true ]]; then
    systemctl enable lightdm-plymouth.service
else
    systemctl enable lightdm.service
fi

# Added autologin group to auto login
if [[ -z "$(cut -d: -f1 /etc/group | grep -x "autologin")" ]]; then
    groupadd autologin
fi
usermod -aG autologin ${username}

# ntp
systemctl enable systemd-timesyncd.service

# Replace auto login user
sed -i s/%USERNAME%/${username}/g /etc/lightdm/lightdm.conf
