#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#

set -e -u

# Default value
# All values can be changed by arguments.
arch="x86_64"
password=alter
boot_splash=false
kernel_config_line=("zen" "vmlinuz-linux-zen" "linux-zen")
theme_name=alter-logo
username='alter'
os_name="Alter Linux"
install_dir="alter"
usershell="/bin/bash"
debug=false
timezone="UTC"
localegen="en_US\\.UTF-8\\"
language="en"

(( "${#}" < 2 )) && echo "There are too few arguments !!" >&2 

# Parse arguments
while getopts 'p:bt:k:xu:o:i:s:da:g:z:l:' arg; do
    case "${arg}" in
        p) password="${OPTARG}" ;;
        b) boot_splash=true ;;
        t) theme_name="${OPTARG}" ;;
        #k) kernel_config_line=(${OPTARG}) ;;
        k) IFS=" " read -r -a kernel_config_line <<< "${OPTARG}" ;;
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
        *) : ;;
    esac
done


# Parse kernel
kernel="${kernel_config_line[0]}"
kernel_filename="${kernel_config_line[1]}"
kernel_mkinitcpio_profile="${kernel_config_line[2]}"

# Make it compatible with previous code
unset OPTIND OPTARG arg

# Load functions
source "/root/functions.sh"


# Check bool type
check_bool boot_splash
check_bool debug


# Set up root user
usermod -s "${usershell}" root
cp -aT /etc/skel/ /root/
echo -e "${password}\n${password}" | passwd root


# Create user
create_user "${username}" "${password}"


# Set up auto login
if [[ -f "/etc/systemd/system/getty@.service.d/autologin.conf" ]]; then
    sed -i "s|%USERNAME%|${username}|g" "/etc/systemd/system/getty@.service.d/autologin.conf"
fi
