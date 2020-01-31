#!/bin/bash

set -e -u

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# usermod -s /usr/bin/zsh root
usermod -s /bin/bash root
cp -aT /etc/skel/ /root/
chmod 700 /root
LC_ALL=C xdg-user-dirs-update
LANG=C xdg-user-dirs-update

<<DISABLED
useradd -m -s /bin/bash alter
groupadd sudo
usermod -G sudo arch
sed -i 's/^#\s*\(%sudo\s\+ALL=(ALL)\s\+ALL\)/\1/' /etc/sudoers
cp -aT /etc/skel/ /home/arch/
DISABLED

[[ -d /usr/share/calamares/branding/manjaro ]] && rm -rf /usr/share/calamares/branding/manjaro
rm /usr/share/backgrounds/xfce/xfce-stripes.png
ln -s /usr/share/backgrounds/alter.png /usr/share/backgrounds/xfce/xfce-stripes.png
chmod 644 /usr/share/backgrounds/alter.png

sed -i 's/#\(PermitRootLogin \).\+/\1yes/' /etc/ssh/sshd_config
sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf

sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' /etc/systemd/logind.conf


# To disable start up of lightdm.
# If it is enable, Users have to enter password.
systemctl disable lightdm
systemctl enable pacman-init.service choose-mirror.service org.cups.cupsd.service
# systemctl set-default multi-user.target
systemctl set-default graphical.target
