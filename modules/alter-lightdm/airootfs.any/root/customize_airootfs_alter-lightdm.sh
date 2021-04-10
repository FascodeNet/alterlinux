#!/usr/bin/env bash

session="$(find "/usr/share/xsessions" -type f -print0 -name "*.desktop" | xargs -0 -I{} bash -c 'basename {} | sed "s|.desktop||g"' | head -n 1 | tail -n 1)"

sed -i "s|%SESSION%|${session}|g" "/etc/lightdm/lightdm.conf.d/02-autologin-session.conf"
