#!/usr/bin/env bash
# shellcheck disable=SC2154

__alteriso_gdm_replace_username() {
    local _username
    _username=$(__alteriso_profiledef_username)

    # Replace auto login user
    sed -i "s/%USERNAME%/${username}/g" "$pacstrap_dir/etc/gdm/custom.conf"
}

__alteriso_lightdm_setup_calamares() {
    local _calamares_service_conf="$pacstrap_dir/usr/share/calamares/modules/services.conf"
    if [[ -e "${_calamares_service_conf}" ]]; then
        sed -i "s|%DM%|gdm|g" "${_calamares_service_conf}"
    fi
}

__alteriso_gdm_customize_airootfs() {
    __alteriso_gdm_replace_username
    __alteriso_lightdm_setup_calamares
}
