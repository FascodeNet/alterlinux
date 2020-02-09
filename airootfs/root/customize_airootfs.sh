#!/bin/bash

set -e -u

# デフォルト値
password=alter
boot_splash=false
theme_name=alter-logo


# オプション解析
while getopts 'p:bt:' arg; do
    case "${arg}" in
        p) password="${OPTARG}" ;;
        b) boot_splash=true ;;
        t) theme_name="${OPTARG}" ;;
    esac
done



sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# usermod -s /usr/bin/zsh root
usermod -s /bin/bash root
cp -aT /etc/skel/ /root/
chmod 700 /root
LC_ALL=C xdg-user-dirs-update
LANG=C xdg-user-dirs-update
echo -e "${password}\n${password}" | passwd root


useradd -m -s /bin/bash alter
groupadd sudo
usermod -G sudo alter
sed -i 's/^#\s*\(%sudo\s\+ALL=(ALL)\s\+ALL\)/\1/' /etc/sudoers
cp -aT /etc/skel/ /home/alter/
chmod 700 -R /home/alter
chown alter:alter -R /home/alter
echo -e "${password}\n${password}" | passwd alter

cat >> /etc/sudoers << 'EOF'
alter ALL=NOPASSWD: /usr/bin/calamares
alter ALL=NOPASSWD: /usr/bin/calamares_polkit
EOF


[[ -d /usr/share/calamares/branding/manjaro ]] && rm -rf /usr/share/calamares/branding/manjaro
if [[ -f /usr/share/backgrounds/xfce/xfce-stripes.png ]]; then
    rm /usr/share/backgrounds/xfce/xfce-stripes.png
    ln -s /usr/share/backgrounds/alter.png /usr/share/backgrounds/xfce/xfce-stripes.png
fi
[[ -f /usr/share/backgrounds/alter.png ]] && chmod 644 /usr/share/backgrounds/alter.png


if [[ $boot_splash = true ]]; then
    rm /usr/share/calamares/modules/services.conf
    mv /usr/share/calamares/modules/services-plymouth.conf /usr/share/calamares/modules/services.conf

    rm /usr/share/calamares/modules/plymouthcfg.conf

    function write () {
        echo $@ >> /usr/share/calamares/modules/plymouthcfg.conf
    }

    write '# Plymouth Configuration Module'
    write '#'
    write '# This module can be used to setup the default plymouth theme to '
    write '# be used with your distribution'
    write '#'
    write '# You should only use this module if the plymouth package is installed '
    write '# on the build configurations of your distribution & the plymouth '
    write '# theme you want to configure is installed as well. If the unpacked'
    write '# filesystem configures a plymouth theme already, there is no need'
    write '# to change it here.'
    write '---'
    write
    write
    write '# Leave this commented if you want to use the default theme '
    write '# shipped with your distribution configurations. Make sure that '
    write '# the theme exists in the themes directory of plymouth path. '
    write '# Debian / Ubuntu comes with themes "joy", "script", "softwaves",'
    write '# possibly others. Look in /usr/share/plymouth/themes for more.'
    write '#'
    write '# Specifying a non-existent theme will leave the plymouth'
    write '# configuration set to that theme. It is up to plymouth to'
    write '# deal with that.'
    write
    write "plymouth_theme: ${theme_name}"

else
    rm /usr/share/calamares/modules/services-plymouth.conf
fi

sed -i 's/#\(PermitRootLogin \).\+/\1yes/' /etc/ssh/sshd_config
sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf

sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' /etc/systemd/logind.conf

# Create Icon Cache
gtk-update-icon-cache -f /usr/share/icons/hicolor


# To disable start up of lightdm.
# If it is enable, Users have to enter password.
systemctl disable lightdm
systemctl enable pacman-init.service choose-mirror.service org.cups.cupsd.service
# systemctl set-default multi-user.target
systemctl set-default graphical.target
