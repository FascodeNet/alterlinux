#!/usr/bin/env bash
# shellcheck disable=SC2154

__alteriso_calamares_validate() {
    local _username
    _username=$(__alteriso_profiledef_username)
    if [[ -z "$_username" || "$_username" == "null" ]]; then
        echo "[alteriso] ERROR: The alter-calamares module requires a non-empty username." >&2
        exit 1
    fi
}

__alteriso_add_validator __alteriso_calamares_validate

__alteriso_calamares_replace_username() {
    local _username
    _username=$(__alteriso_profiledef_username)
    sed -i "s|%USERNAME%|${_username}|g" "$pacstrap_dir/etc/calamares/modules/removeuser.conf"
}

__alteriso_calamares_customize_airootfs() {
    __alteriso_calamares_replace_username
}
