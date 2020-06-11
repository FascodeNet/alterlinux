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


# Check whether true or false is assigned to the variable.
function check_bool() {
    local
    case $(eval echo '$'${1}) in
        true | false) : ;;
                   *) echo "The value ${boot_splash} set is invalid" >&2 ;;
    esac
}

check_bool boot_splash
check_bool rebuild
check_bool japanese


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


# Enable and generate languages.
sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
if [[ ${japanese} = true ]]; then
    sed -i 's/#\(ja_JP\.UTF-8\)/\1/' /etc/locale.gen
fi
locale-gen


# Setting the time zone.
if [[ ${japanese} = true ]]; then
    ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
else
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime
fi


# Set os name
sed -i s/%OS_NAME%/"${os_name}"/g /etc/skel/Desktop/calamares.desktop


# Creating a root user.
# usermod -s /usr/bin/zsh root
function user_check () {
if [[ $(getent passwd $1 > /dev/null ; printf $?) = 0 ]]; then
    if [[ -z $1 ]]; then
        echo -n "false"
    fi
    echo -n "true"
else
    echo -n "false"
fi
}

if [[ $(user_check root) = false ]]; then
    usermod -s "${usershell}" root
    cp -aT /etc/skel/ /root/
    chmod 700 /root
    LC_ALL=C LANG=C xdg-user-dirs-update
fi
echo -e "${password}\n${password}" | passwd root

# Allow sudo group to run sudo
sed -i 's/^#\s*\(%sudo\s\+ALL=(ALL)\s\+ALL\)/\1/' /etc/sudoers

# Create a user.
# create_user <username> <password>
function create_user () {
    local _password
    local _username

    _username=${1}
    _password=${2}

    set +u
    if [[ -z "${_username}" ]]; then
        echo "User name is not specified." >&2
        return 1
    fi
    if [[ -z "${_password}" ]]; then
        echo "No password has been specified." >&2
        return 1
    fi
    set -u

    if [[ $(user_check ${_username}) = false ]]; then
        useradd -m -s ${usershell} ${_username}
        groupadd sudo
        usermod -U -g ${_username} ${_username}
        usermod -aG sudo ${_username}
        usermod -aG storage ${_username}
        cp -aT /etc/skel/ /home/${_username}/
    fi
    chmod 700 -R /home/${_username}
    chown ${_username}:${_username} -R /home/${_username}
    echo -e "${_password}\n${_password}" | passwd ${_username}
    set -u
}

create_user "${username}" "${password}"


# Set up auto login
if [[ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]]; then
    sed -i s/%USERNAME%/"${username}"/g /etc/systemd/system/getty@tty1.service.d/autologin.conf
fi


# Set to execute calamares without password as alter user.
cat >> /etc/sudoers << "EOF"
Defaults pwfeedback
EOF
echo "${username} ALL=NOPASSWD: ALL" >> /etc/sudoers.d/alterlive


# Chnage sudoers permission
chmod 750 -R /etc/sudoers.d/
chown root:root -R /etc/sudoers.d/


# Configure Plymouth settings
if [[ $boot_splash = true ]]; then
    # Edit calamares settings for Plymouth.

    # Use lightdm-plymouth instead of lightdm.
    remove /usr/share/calamares/modules/services.conf
    mv /usr/share/calamares/modules/services-plymouth.conf /usr/share/calamares/modules/services.conf

    # Back up default plymouth settings.
    # cp /usr/share/calamares/modules/plymouthcfg.conf /usr/share/calamares/modules/plymouthcfg.conf.org

    # Override theme settings.
    remove /usr/share/calamares/modules/plymouthcfg.conf
    echo '---' > /usr/share/calamares/modules/plymouthcfg.conf
    echo "plymouth_theme: ${theme_name}" >> /usr/share/calamares/modules/plymouthcfg.conf

    # Override plymouth settings.
    sed -i s/%PLYMOUTH_THEME%/"${theme_name}"/g /etc/plymouth/plymouthd.conf

    # Apply plymouth theme settings.
    plymouth-set-default-theme ${theme_name}
else
    # Delete the configuration file for plymouth.
    remove /usr/share/calamares/modules/services-plymouth.conf
    remove /etc/plymouth
fi


# Japanese
if [[ ${japanese} = true ]]; then
    # Change the language to Japanese.

    remove /etc/locale.conf
    echo 'LANG=ja_JP.UTF-8' > /etc/locale.conf
fi


# Calamares configs

# Replace the configuration file.
# initcpio
remove /usr/share/calamares/modules/initcpio.conf
mv /usr/share/calamares/modules/initcpio/initcpio-${kernel}.conf /usr/share/calamares/modules/initcpio.conf

# unpackfs
remove /usr/share/calamares/modules/unpackfs.conf
mv /usr/share/calamares/modules/unpackfs/unpackfs-${kernel}.conf /usr/share/calamares/modules/unpackfs.conf

# Remove configuration files for other kernels.
remove /usr/share/calamares/modules/initcpio/
remove /usr/share/calamares/modules/unpackfs/

# Set up calamares removeuser
sed -i s/%USERNAME%/${username}/g /usr/share/calamares/modules/removeuser.conf

# Set user shell
sed -i "s|%USERSHELL%|'${usershell}'|g" /usr/share/calamares/modules/users.conf

# Set INSTALL_DIR
sed -i s/%INSTALL_DIR%/"${install_dir}"/g /usr/share/calamares/modules/unpackfs.conf

# Set ARCH
sed -i s/%ARCH%/"${arch}"/g /usr/share/calamares/modules/unpackfs.conf

# Add disabling of sudo setting
echo "remove /etc/sudoers.d/alterlive " >> /usr/share/calamares/final-process


# Set os name
sed -i s/%OS_NAME%/"${os_name}"/g /usr/lib/os-release


# Enable root login with SSH.
sed -i 's/#\(PermitRootLogin \).\+/\1yes/' /etc/ssh/sshd_config


# Comment out the mirror list.
sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist


# Set to save journal logs only in memory.
sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf


# Set the operation when each power button is pressed in systemd power management.
sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' /etc/systemd/logind.conf


# Create new icon cache
# This is because alter icon was added by airootfs.
gtk-update-icon-cache -f /usr/share/icons/hicolor


# Enable graphical.
systemctl set-default graphical.target


# Enable services.
systemctl enable pacman-init.service
systemctl enable choose-mirror.service
systemctl enable org.cups.cupsd.service
systemctl enable NetworkManager.service


# TLP
# See ArchWiki for details.
systemctl enable tlp.service
systemctl mask systemd-rfkill.service
systemctl mask systemd-rfkill.socket
