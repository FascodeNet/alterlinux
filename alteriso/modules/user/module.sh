#!/usr/bin/env bash
# shellcheck disable=SC2154

_make_customize_airootfs_user() {
    local _username
    _username=$(__alteriso_profiledef | jq -r ".username")

    _msg_info "Setting up auto-login for user: $_username"

    local passwd=()
    passwd+=("${_username}:x:1000:1000:Live User:/home/${_username}:/bin/zsh")
    printf '%s\n' "${passwd[@]}" >>"${pacstrap_dir}/etc/passwd"

    local shadow=()
    shadow+=("${_username}::14871::::::")
    printf '%s\n' "${shadow[@]}" >>"${pacstrap_dir}/etc/shadow"

    local group=()
    group+=("$_username:x:1000:")
    printf '%s\n' "${group[@]}" >>"${pacstrap_dir}/etc/group"

    local _autologin_conf="$pacstrap_dir/etc/systemd/system/getty@tty1.service.d/autologin.conf"
    if [[ -e "${_autologin_conf}" ]]; then
        sed -i "s|%ALTERISO_USERNAME%|${_username}|g" "${_autologin_conf}"
    fi

    echo "${_username} ALL=NOPASSWD: ALL" >> "$pacstrap_dir/etc/sudoers.d/alteriso_live"

    _msg_info "Setting up user for auto-login: $_username"
}
