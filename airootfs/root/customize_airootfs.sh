#!/usr/bin/env bash

set -e -u


# Default value
# All values can be changed by arguments.
password=alter
boot_splash=false
kernel=core
theme_name=alter-logo
rebuild=false
japanese=false
username='alter'


# Parse arguments
while getopts 'p:bt:k:rxju:' arg; do
    case "${arg}" in
        p) password="${OPTARG}" ;;
        b) boot_splash=true ;;
        t) theme_name="${OPTARG}" ;;
        k) kernel="${OPTARG}" ;;
        r) rebuild=true ;;
        j) japanese=true;;
        u) username="${OPTARG}" ;;
        x) set -xv ;;
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


# If rebuild is enabled, do not create users.
# This is described in detail on ArchWiki.
if [[ ${rebuild} = false ]]; then
    # Creating a root user.
    # usermod -s /usr/bin/zsh root

    usermod -s /bin/bash root
    cp -aT /etc/skel/ /root/
    chmod 700 /root
    LC_ALL=C xdg-user-dirs-update
    LANG=C xdg-user-dirs-update
    echo -e "${password}\n${password}" | passwd root

    # Allow sudo group to run sudo
    sed -i 's/^#\s*\(%sudo\s\+ALL=(ALL)\s\+ALL\)/\1/' /etc/sudoers

    # Create alter user.
    # create_user -u <username> -p <password>
    function create_user () {
        local _password
        local _username
        _password=${password}
        _username=${username}

        # Option analysis
        while getopts 'p:u:' arg; do
            case "${arg}" in
                p) _password="${OPTARG}" ;;
                u) _username="${OPTARG}" ;;
            esac
        done

        useradd -m -s /bin/bash ${_username}
        groupadd sudo
        usermod -U -g ${_username} -G sudo ${_username}
        cp -aT /etc/skel/ /home/${_username}/
        chmod 700 -R /home/${_username}
        chown ${_username}:${_username} -R /home/${_username}
        echo -e "${_password}\n${_password}" | passwd ${_username}
        set -u
    }

    create_user -u "${username}" -p "${password}"
fi


# Set up auto login
if [[ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]]; then
    sed -i s/%USERNAME%/${username}/ /etc/systemd/system/getty@tty1.service.d/autologin.conf
fi


# Set to execute calamares without password as alter user.
cat >> /etc/sudoers << 'EOF'
alter ALL=NOPASSWD: /usr/bin/calamares
alter ALL=NOPASSWD: /usr/bin/calamares_polkit
Defaults pwfeedback
EOF


# Replace wallpaper.
if [[ -f /usr/share/backgrounds/xfce/xfce-stripes.png ]]; then
    remove /usr/share/backgrounds/xfce/xfce-stripes.png
    ln -s /usr/share/backgrounds/alter.png /usr/share/backgrounds/xfce/xfce-stripes.png
fi
[[ -f /usr/share/backgrounds/alter.png ]] && chmod 644 /usr/share/backgrounds/alter.png


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

    # Apply plymouth theme settings.
    plymouth-set-default-theme ${theme_name}
else
    # Delete the configuration file for plymouth.
    remove /usr/share/calamares/modules/services-plymouth.conf
fi


# Japanese
if [[ ${japanese} = true ]]; then
    # Change the language to Japanese.

    remove /etc/locale.conf
    echo 'LANG=ja_JP.UTF-8' > /etc/locale.conf
fi


# If the specified kernel is different from calamares configuration, replace the configuration file.
if [[ ! ${kernel} = "zen" ]]; then
    # initcpio
    remove /usr/share/calamares/modules/initcpio.conf
    mv /usr/share/calamares/modules/initcpio/initcpio-${kernel}.conf /usr/share/calamares/modules/initcpio.conf

    # unpackfs
    remove /usr/share/calamares/modules/unpackfs.conf
    mv /usr/share/calamares/modules/unpackfs/unpackfs-${kernel}.conf /usr/share/calamares/modules/unpackfs.conf
fi
# Remove configuration files for other kernels.
remove /usr/share/calamares/modules/initcpio/
remove /usr/share/calamares/modules/unpackfs/


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


# Disable services.
# To disable start up of lightdm.
# If it is enable, Users have to enter password.
systemctl disable lightdm
if [[ ${boot_splash} = true ]]; then
    systemctl disable lightdm-plymouth.service
fi


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
