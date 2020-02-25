#!/bin/bash

set -e -u

# デフォルト値
password=alter
boot_splash=false
kernel=
theme_name=alter-logo



# オプション解析
while getopts 'p:bt:k:' arg; do
    case "${arg}" in
        p) password="${OPTARG}" ;;
        b) boot_splash=true ;;
        t) theme_name="${OPTARG}" ;;
        k) kernel="${OPTARG}" ;;
    esac
done


# Enable and generate languages.
sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
# sed -i 's/#\(ja_JP\.UTF-8\)/\1/' /etc/locale.gen
locale-gen


# Setting the time zone.
ln -sf /usr/share/zoneinfo/UTC /etc/localtime


# Creating a root user.
# usermod -s /usr/bin/zsh root
usermod -s /bin/bash root
cp -aT /etc/skel/ /root/
chmod 700 /root
LC_ALL=C xdg-user-dirs-update
LANG=C xdg-user-dirs-update
echo -e "${password}\n${password}" | passwd root


# Create alter user.
useradd -m -s /bin/bash alter
groupadd sudo
usermod -G sudo alter
sed -i 's/^#\s*\(%sudo\s\+ALL=(ALL)\s\+ALL\)/\1/' /etc/sudoers
cp -aT /etc/skel/ /home/alter/
chmod 700 -R /home/alter
chown alter:alter -R /home/alter
echo -e "${password}\n${password}" | passwd alter


# Set to execute calamares without password as alter user.
cat >> /etc/sudoers << 'EOF'
alter ALL=NOPASSWD: /usr/bin/calamares
alter ALL=NOPASSWD: /usr/bin/calamares_polkit
EOF


# Delete unnecessary files for Manjaro.
[[ -d /usr/share/calamares/branding/manjaro ]] && rm -rf /usr/share/calamares/branding/manjaro


# Replace wallpaper.
if [[ -f /usr/share/backgrounds/xfce/xfce-stripes.png ]]; then
    rm /usr/share/backgrounds/xfce/xfce-stripes.png
    ln -s /usr/share/backgrounds/alter.png /usr/share/backgrounds/xfce/xfce-stripes.png
fi
[[ -f /usr/share/backgrounds/alter.png ]] && chmod 644 /usr/share/backgrounds/alter.png


# Replace calamares settings when plymouth is enabled.
if [[ $boot_splash = true ]]; then
    rm /usr/share/calamares/modules/services.conf
    mv /usr/share/calamares/modules/services-plymouth.conf /usr/share/calamares/modules/services.conf

    cp /usr/share/calamares/modules/plymouthcfg.conf /usr/share/calamares/modules/plymouthcfg.conf.org
    echo '---' > /usr/share/calamares/modules/plymouthcfg.conf
    echo "plymouth_theme: ${theme_name}" >> /usr/share/calamares/modules/plymouthcfg.conf

else
    rm /usr/share/calamares/modules/services-plymouth.conf
fi


# Replace calamares settings when lts kernel is enabled.
if [[ -n ${kernel} ]]; then
    # initcpio
    [[ -f /usr/share/calamares/modules/initcpio.conf ]] && rm -f /usr/share/calamares/modules/initcpio.conf
    mv /usr/share/calamares/modules/initcpio/initcpio-${kernel}.conf /usr/share/calamares/modules/initcpio.conf

    # unpackfs
    [[ -f /usr/share/calamares/modules/unpackfs.conf ]] && rm -f /usr/share/calamares/modules/unpackfs.conf
    mv /usr/share/calamares/modules/unpackfs/unpackfs-${kernel}.conf /usr/share/calamares/modules/unpackfs.conf
fi
[[ -d /usr/share/calamares/modules/initcpio/ ]] && rm -rf /usr/share/calamares/modules/initcpio/
[[ -d /usr/share/calamares/modules/unpackfs/ ]] && rm -rf /usr/share/calamares/modules/unpackfs/


# Enable root login with SSH.
sed -i 's/#\(PermitRootLogin \).\+/\1yes/' /etc/ssh/sshd_config


# Enable all mirror lists.
sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist


# Set to save journal logs only in memory.
sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf


# Set the operation when each power button is pressed in systemd power management.
sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' /etc/systemd/logind.conf


# Create new icon cache
gtk-update-icon-cache -f /usr/share/icons/hicolor


# To disable start up of lightdm.
# If it is enable, Users have to enter password.
systemctl disable lightdm
if [[ ${boot_splash} = true ]]; then
    systemctl disable lightdm-plymouth.service
fi
systemctl enable pacman-init.service 
systemctl enable choose-mirror.service 
systemctl enable org.cups.cupsd.service

# TLP
systemctl enable tlp.service
systemctl enable tlp-sleep.service
systemctl mask systemd-rfkill.service
systemctl mask systemd-rfkill.socket


# systemctl set-default multi-user.target
systemctl set-default graphical.target
