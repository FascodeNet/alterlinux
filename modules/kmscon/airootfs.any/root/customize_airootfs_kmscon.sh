#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#

# Copy config file for getty@tty1.service to kmsconvt@tty1.service
if [[ -f "/etc/systemd/system/getty@tty1.service.d/autologin.conf" ]]; then
    mkdir -p "/etc/systemd/system/kmsconvt@tty1.service.d/"
    cp "/etc/systemd/system/getty@tty1.service.d/autologin.conf" "/etc/systemd/system/kmsconvt@tty1.service.d/autologin.conf" 
fi

# Disable default tty
_systemd_service disable "getty@tty1.service"
_systemd_service enable "kmsconvt@tty1.service"

# Run KMSCON for all tty
ln -s "/usr/lib/systemd/system/kmsconvt@.service" "/etc/systemd/system/autovt@.service"
