#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#

# Enable and generate languages.
sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
if [[ ! "${localegen}" = "en_US\\.UTF-8\\" ]]; then
    sed -i "s/#\(${localegen})/\1/" /etc/locale.gen
fi
locale-gen

# Create root user directory
run_additional_command "xdg-user-dirs-update" "LC_ALL=C LANG=C xdg-user-dirs-update"

# Setting the time zone.
ln -sf "/usr/share/zoneinfo/${timezone}" /etc/localtime

# Allow sudo group to run sudo
sed -i 's/^#\s*\(%sudo\s\+ALL=(ALL)\s\+ALL\)/\1/' /etc/sudoers

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

# Set to execute sudo without password as alter user.
cat >> /etc/sudoers << "EOF"
Defaults pwfeedback
EOF
echo "${username} ALL=NOPASSWD: ALL" >> /etc/sudoers.d/alterlive


# Chnage sudoers permission
chmod 750 -R /etc/sudoers.d/
chown root:root -R /etc/sudoers.d/

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
