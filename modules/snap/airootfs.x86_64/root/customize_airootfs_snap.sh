#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#

_safe_systemctl enable snapd.apparmor.service
_safe_systemctl enable apparmor.service
_safe_systemctl enable snapd.socket
_safe_systemctl enable snapd.service
