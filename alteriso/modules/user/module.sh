#!/usr/bin/env bash
# shellcheck disable=SC2154

_make_customize_airootfs_passwd() {
    local _username
    _username=$(__alteriso_profiledef | jq -r ".username")

    _msg_info "Setting up auto-login for user: $_username"

    passwd+=("${_username}:x:1000:1000:Live User:/home/${_username}:/bin/zsh")
    printf '%s\n' "${passwd[@]}" >>"${pacstrap_dir}/etc/passwd"
    # shellcheck disable=SC2034
    # file_permissions["/etc/passwd"]="0:0:644"
    _msg_info "Setting up user for auto-login: $_username"
}
