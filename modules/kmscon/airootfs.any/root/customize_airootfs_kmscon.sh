#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#

# Copy config file for getty@.service to kmsconvt@.service
if [[ -f "/etc/systemd/system/getty@.service.d/autologin.conf" ]]; then
    mkdir -p "/etc/systemd/system/kmsconvt@.service.d/"
    cp "/etc/systemd/system/getty@.service.d/autologin.conf" "/etc/systemd/system/kmsconvt@.service.d/autologin.conf" 
fi

# Disable default tty
_safe_systemctl disable "getty@tty1.service" "getty@.service"
_safe_systemctl enable "kmsconvt@tty1.service"
_safe_systemctl enable "kmsconvt@tty2.service"


# Do not run setterm
remove /etc/profile.d/disable-beep.sh

# Run KMSCON for all tty
ln -s "/usr/lib/systemd/system/kmsconvt@.service" "/etc/systemd/system/autovt@.service"
