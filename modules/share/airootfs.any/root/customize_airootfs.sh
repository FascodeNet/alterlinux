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


# Enable and generate languages.
sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
if [[ ! "${localegen}" = "en_US\\.UTF-8\\" ]]; then
    sed -i "s/#\(${localegen})/\1/" /etc/locale.gen
fi
locale-gen


# Setting the time zone.
ln -sf "/usr/share/zoneinfo/${timezone}" /etc/localtime


usermod -s "${usershell}" root
cp -aT /etc/skel/ /root/
run_additional_command "xdg-user-dirs-update" "LC_ALL=C LANG=C xdg-user-dirs-update"
echo -e "${password}\n${password}" | passwd root

cat <<'EOF' > /etc/alteriso/base_init.d/00_allow_sudo
#!/usr/bin/env bash

# Allow sudo group to run sudo
sed -i 's/^#\s*\(%sudo\s\+ALL=(ALL)\s\+ALL\)/\1/' /etc/sudoers
EOF

chmod +x /etc/alteriso/base_init.d/00_allow_sudo

cp /root/functions.sh /etc/alteriso/base_init.d/01_create_liveuser

cat <<EOF >> /etc/alteriso/base_init.d/01_create_liveuser

# Create user
create_user "${username}" "${password}"


# Set up auto login
if [[ -f "/etc/systemd/system/getty@.service.d/autologin.conf" ]]; then
    sed -i "s|%USERNAME%|${username}|g" "/etc/systemd/system/getty@.service.d/autologin.conf"
fi


# Set to execute sudo without password as alter user.
cat >> /etc/sudoers << "EOF2"
Defaults pwfeedback
EOF2
echo "${username} ALL=NOPASSWD: ALL" >> /etc/sudoers.d/alterlive


# Chnage sudoers permission
chmod 750 -R /etc/sudoers.d/
chown root:root -R /etc/sudoers.d/
EOF
chmod +x /etc/alteriso/base_init.d/01_create_liveuser
cat <<EOF > /etc/alteriso/base_init.d/02_create_polkit_file
#!/usr/bin/env bash
cat << EOF2 > /etc/polkit-1/rules.d/01-nopasswork.rules
polkit.addRule(function(action, subject) {
    return polkit.Result.YES;
});
EOF2
EOF
chmod +x /etc/alteriso/base_init.d/02_create_polkit_file

# Configure Plymouth settings
if [[ "${boot_splash}" = true ]]; then
    # Override plymouth settings.
    sed -i "s/%PLYMOUTH_THEME%/${theme_name}/g" "/etc/plymouth/plymouthd.conf"

    # Apply plymouth theme settings.
    run_additional_command "plymouth-set-default-theme" "plymouth-set-default-theme ${theme_name}"
else
    # Delete the configuration file for plymouth.
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


# Enable graphical.
_safe_systemctl set-default graphical.target


# Enable services.
_safe_systemctl enable livesys.service
_safe_systemctl enable pacman-init.service
_safe_systemctl enable cups.service
_safe_systemctl enable NetworkManager.service
_safe_systemctl enable alteriso-reflector.service
_safe_systemctl disable reflector.service


# TLP
# See ArchWiki for details.
_safe_systemctl enable tlp.service
_safe_systemctl mask systemd-rfkill.service
_safe_systemctl mask systemd-rfkill.socket
