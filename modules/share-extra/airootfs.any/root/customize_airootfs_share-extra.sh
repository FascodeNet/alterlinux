#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#

# Firewall
_safe_systemctl enable ufw.service

# Added autologin group to auto login
_groupadd autologin
usermod -aG autologin ${username}

# ntp
_safe_systemctl enable systemd-timesyncd.service


# Change aurorun files permission
chmod 755 "/home/${username}/.config/autostart/"* "/etc/skel/.config/autostart/"* || true
