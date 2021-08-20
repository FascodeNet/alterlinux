#!/usr/bin/env bash

# Pipewire
# Do not use _safe_systemctl because pipewire services are not system but user
# Use flag "--user --global"
# https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/923
for _service in "pipewire.service" "pipewire-pulse.service"; do
    if systemctl --user --global cat "${_service}" 1> /dev/null 2>&1; then
        systemctl --user --global enable "${_service}"
    fi
done

# Enable bluetooth support for pipewire
if [[ -f "/etc/pipewire/media-session.d/media-session.conf" ]]; then
    sed -i "s|#bluez5|bluez5 |g" "/etc/pipewire/media-session.d/media-session.conf"
fi

