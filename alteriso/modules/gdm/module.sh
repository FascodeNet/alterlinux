#!/usr/bin/env bash
# shellcheck disable=SC2154

__alteriso_gdm_replace_username() {
    local _username
    _username=$(__alteriso_profiledef_username)

    # Replace auto login user
    sed -i "s/%USERNAME%/${_username}/g" "$pacstrap_dir/etc/gdm/custom.conf"
}

# The calamares services config enables lightdm by default.
__alteriso_gdm_setup_calamares() {
    local _calamares_service_conf="$pacstrap_dir/etc/calamares/modules/services-systemd.conf"
    if [[ -e "${_calamares_service_conf}" ]]; then
        sed -i 's|name: "lightdm"|name: "gdm"|' "${_calamares_service_conf}"
    fi
}

# gdm.service conflicts with getty@tty1.service.
__alteriso_gdm_disable_getty_autologin() {
    local _autologin_conf="$pacstrap_dir/etc/systemd/system/getty@tty1.service.d/autologin.conf"
    if [[ -e "${_autologin_conf}" ]]; then
        rm -f "${_autologin_conf}"
    fi
}

__alteriso_gdm_customize_airootfs() {
    __alteriso_gdm_replace_username
    __alteriso_gdm_setup_calamares
    __alteriso_gdm_disable_getty_autologin
}
