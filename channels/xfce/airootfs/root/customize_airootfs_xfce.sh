#!/usr/bin/env bash

set -e -u


# Default value
# All values can be changed by arguments.
password=alter
boot_splash=false
kernel=core
theme_name=alter-logo
rebuild=false
japanese=false
username='alter'


# Parse arguments
while getopts 'p:bt:k:rxju:' arg; do
    case "${arg}" in
        p) password="${OPTARG}" ;;
        b) boot_splash=true ;;
        t) theme_name="${OPTARG}" ;;
        k) kernel="${OPTARG}" ;;
        r) rebuild=true ;;
        j) japanese=true;;
        u) username="${OPTARG}" ;;
        x) set -xv ;;
    esac
done


# Replace wallpaper.
if [[ -f /usr/share/backgrounds/xfce/xfce-stripes.png ]]; then
    remove /usr/share/backgrounds/xfce/xfce-stripes.png
    ln -s /usr/share/backgrounds/alter.png /usr/share/backgrounds/xfce/xfce-stripes.png
fi
[[ -f /usr/share/backgrounds/alter.png ]] && chmod 644 /usr/share/backgrounds/alter.png