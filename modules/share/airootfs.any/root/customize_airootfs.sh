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


# Check whether true or false is assigned to the variable.
function check_bool() {
    local
    case $(eval echo '$'${1}) in
        true | false) : ;;
                   *) echo "The value ${boot_splash} set is invalid" >&2 ;;
    esac
}

check_bool boot_splash
check_bool debug


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


function installedpkg () {
    if pacman -Qq "${1}" 1>/dev/null 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Enable and generate languages.
sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
if [[ ! "${localegen}" = "en_US\\.UTF-8\\" ]]; then
    sed -i "s/#\(${localegen})/\1/" /etc/locale.gen
fi
locale-gen


# Setting the time zone.
ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime


# Create Calamares Entry
if [[ -f "/etc/skel/Desktop/calamares.desktop" ]]; then
    cp -a "/etc/skel/Desktop/calamares.desktop" "/usr/share/applications/calamares.desktop"
fi


# user_check <name>
function user_check () {
    if [[ ! -v 1 ]]; then return 2; fi
    getent passwd "${1}" > /dev/null
}

# Execute only if the command exists
# run_additional_command [command name] [command to actually execute]
run_additional_command() {
    if [[ -f "$(type -p "${1}" 2> /dev/null)" ]]; then
        shift 1
        eval "${@}"
    fi
}

usermod -s "${usershell}" root
cp -aT /etc/skel/ /root/
if [[ -f "$(type -p "xdg-user-dirs-update" 2> /dev/null)" ]]; then LC_ALL=C LANG=Cxdg-user-dirs-update; fi
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

    if user_check "${_username}"; then
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
if [[ "${boot_splash}" = true ]]; then
    # Edit calamares settings for Plymouth.

    # Use lightdm-plymouth instead of lightdm.
    remove "/usr/share/calamares/modules/services.conf"
    mv "/usr/share/calamares/modules/services-plymouth.conf" "/usr/share/calamares/modules/services.conf"

    # Back up default plymouth settings.
    # cp /usr/share/calamares/modules/plymouthcfg.conf /usr/share/calamares/modules/plymouthcfg.conf.org

    # Override theme settings.
    remove "/usr/share/calamares/modules/plymouthcfg.conf"
    echo '---' > "/usr/share/calamares/modules/plymouthcfg.conf"
    echo "plymouth_theme: ${theme_name}" >> "/usr/share/calamares/modules/plymouthcfg.conf"

    # Override plymouth settings.
    sed -i "s/%PLYMOUTH_THEME%/${theme_name}/g" "/etc/plymouth/plymouthd.conf"

    # Apply plymouth theme settings.
    run_additional_command "plymouth-set-default-theme" "plymouth-set-default-theme ${theme_name}"
else
    # Delete the configuration file for plymouth.
    remove "/usr/share/calamares/modules/services-plymouth.conf"
    remove "/etc/plymouth"
fi


# Japanese
if [[ "${language}" = "ja" ]]; then
    # Change the language to Japanese.

    remove /etc/locale.conf
    echo 'LANG=ja_JP.UTF-8' > /etc/locale.conf
fi

#TUI Installer configs

echo "${kernel_filename}" > /root/kernel_filename

# Calamares configs

# Replace the configuration file.
# initcpio
sed -i "s/%MKINITCPIO_PROFILE%/${kernel_mkinitcpio_profile}/g" /usr/share/calamares/modules/initcpio.conf

# unpackfs
sed -i "s|%KERNEL_FILENAME%|${kernel_filename}|g" /usr/share/calamares/modules/unpackfs.conf

# Remove configuration files for other kernels.
remove "/usr/share/calamares/modules/initcpio/"
remove "/usr/share/calamares/modules/unpackfs/"

# Set up calamares removeuser
sed -i "s/%USERNAME%/${username}/g" "/usr/share/calamares/modules/removeuser.conf"

# Set user shell
sed -i "s|%USERSHELL%|${usershell}|g" "/usr/share/calamares/modules/users.conf"

# Set INSTALL_DIR
sed -i "s/%INSTALL_DIR%/${install_dir}/g" "/usr/share/calamares/modules/unpackfs.conf"

# Set ARCH
sed -i "s/%ARCH%/${arch}/g" "/usr/share/calamares/modules/unpackfs.conf"

# Add disabling of sudo setting
echo -e "\nremove \"/etc/sudoers.d/alterlive\"" >> "/usr/share/calamares/final-process"


# Set os name
sed -i "s/%OS_NAME%/${os_name}/g" "/usr/lib/os-release"


# Enable root login with SSH.
if [[ -f "/etc/ssh/sshd_config" ]]; then
    sed -i 's/#\(PermitRootLogin \).\+/\1yes/' "/etc/ssh/sshd_config"
fi

# Un comment the mirror list.
sed -i "s/#Server/Server/g" "/etc/pacman.d/mirrorlist"

# Set the os name to grub
grub_os_name="${os_name%' Linux'}"
sed -i -r  "s/(GRUB_DISTRIBUTOR=).*/\1\"${grub_os_name}\"/g" "/etc/default/grub"

# Create new icon cache
# This is because alter icon was added by airootfs.
run_additional_command "gtk-update-icon-cache -f /usr/share/icons/hicolor"


# systemctl helper
# Execute the subcommand only when the specified unit is available.
# Usage: _systemd_service <systemctl subcommand> <service1> <service2> ...
_systemd_service(){
    local _service
    local _command="${1}"
    shift 1
    for _service in "${@}"; do
        # https://unix.stackexchange.com/questions/539147/systemctl-check-if-a-unit-service-or-target-exists
        if (( "$(systemctl list-unit-files "${_service}" | wc -l)" > 3 )); then
            systemctl ${_command} "${_service}"
        else
            echo "${_service} was not found" >&2
        fi
    done
}

# Enable graphical.
_systemd_service set-default graphical.target


# Enable services.
_systemd_service enable pacman-init.service
_systemd_service enable cups.service
_systemd_service enable NetworkManager.service
_systemd_service enable alteriso-reflector.service
_systemd_service disable reflector.service


# TLP
# See ArchWiki for details.
_systemd_service enable tlp.service
_systemd_service mask systemd-rfkill.service
_systemd_service mask systemd-rfkill.socket
