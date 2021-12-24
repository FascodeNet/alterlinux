#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#

# Bluetooth
rfkill unblock all
_safe_systemctl enable bluetooth

# Update system datebase
if type -p dconf 1>/dev/null 2>/dev/null; then
    dconf update
fi
