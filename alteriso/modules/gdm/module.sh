#!/usr/bin/env bash
# shellcheck disable=SC2154

__alteriso_gdm_replace_username() {
    local _username
    _username=$(__alteriso_profiledef_username)

    # Replace auto login user
    sed -i "s/%USERNAME%/${username}/g" "$pacstrap_dir/etc/gdm/custom.conf"
}

# LLM Modified: The calamares services config moved to /etc and enables lightdm by default - Claude
__alteriso_gdm_setup_calamares() {
    local _calamares_service_conf="$pacstrap_dir/etc/calamares/modules/services-systemd.conf"
    if [[ -e "${_calamares_service_conf}" ]]; then
        sed -i 's|name: "lightdm"|name: "gdm"|' "${_calamares_service_conf}"
    fi
}

__alteriso_gdm_customize_airootfs() {
    __alteriso_gdm_replace_username
    __alteriso_gdm_setup_calamares
}
