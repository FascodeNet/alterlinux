#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#

# Enable LightDM to auto login
if [[ "${boot_splash}" =  true ]]; then
    systemctl enable lightdm-plymouth.service
else
    systemctl enable lightdm.service
fi

# Replace auto login user
sed -i s/%USERNAME%/${username}/g /etc/lightdm/lightdm.conf

# Replace password for screensaver comment
sed -i s/%PASSWORD%/${password}/g "/etc/dconf/db/local.d/02-disable-lock"

# Update system datebase
dconf update
