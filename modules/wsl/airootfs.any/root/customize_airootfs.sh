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


# Parse arguments
while getopts 'p:bt:k:rxu:o:i:s:da:g:z:l:' arg; do
    case "${arg}" in
        p) password="${OPTARG}" ;;
        b) boot_splash=true ;;
        t) theme_name="${OPTARG}" ;;
        k) kernel_config_line=(${OPTARG}) ;;
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
kernel_filename="${kernel_config_line[1]}"
kernel_mkinitcpio_profile="${kernel_config_line[2]}"

# Make it compatible with previous code
unset OPTIND OPTARG arg

# Load functions
source "/root/functions.sh"


# Check bool type
check_bool boot_splash
check_bool debug


# Enable and generate languages.
sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
if [[ ! "${localegen}" = "en_US\\.UTF-8\\" ]]; then
    sed -i "s/#\(${localegen})/\1/" /etc/locale.gen
fi
locale-gen


# Setting the time zone.
ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime


usermod -s "${usershell}" root
cp -aT /etc/skel/ /root/
if [[ -f "$(type -p "xdg-user-dirs-update" 2> /dev/null)" ]]; then LC_ALL=C LANG=Cxdg-user-dirs-update; fi
echo -e "${password}\n${password}" | passwd root

# Allow sudo group to run sudo
sed -i 's/^#\s*\(%sudo\s\+ALL=(ALL)\s\+ALL\)/\1/' /etc/sudoers


# Create user
create_user "${username}" "${password}"



# Chnage sudoers permission
chmod 750 -R /etc/sudoers.d/
chown root:root -R /etc/sudoers.d/




# Japanese
if [[ "${language}" = "ja" ]]; then
    # Change the language to Japanese.

    remove /etc/locale.conf
    echo 'LANG=ja_JP.UTF-8' > /etc/locale.conf
fi


# Set os name
sed -i "s/%OS_NAME%/${os_name}/g" "/usr/lib/os-release"

# Un comment the mirror list.
sed -i "s/#Server/Server/g" "/etc/pacman.d/mirrorlist"
