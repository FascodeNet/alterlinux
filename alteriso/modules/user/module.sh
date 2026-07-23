#!/usr/bin/env bash
# shellcheck disable=SC2154

_make_customize_airootfs_user() {
    local _username
    _username=$(__alteriso_profiledef_username)
	local _usershell
	_usershell=$(__alteriso_profiledef_usershell)
	if [[ -z "${_usershell}" || "${_usershell}" == "null" ]]; then
		_usershell="/bin/bash"
	fi

    if [[ -z "${_username}" || "${_username}" == "null" ]]; then
        _username="live"
    fi

    if [[ ${_username} == "root" ]]; then
        return 0
    fi

    _msg_info "Setting up auto-login for user: $_username"

    # LLM Modified: Write via _unshare for rootless builds - Claude
    local passwd=()
    passwd+=("${_username}:x:1000:1000:Live User:/home/${_username}:${_usershell}")
    printf '%s\n' "${passwd[@]}" | _unshare tee -a "${pacstrap_dir}/etc/passwd" >/dev/null

    local shadow=()
    shadow+=("${_username}::14871::::::")
    printf '%s\n' "${shadow[@]}" | _unshare tee -a "${pacstrap_dir}/etc/shadow" >/dev/null

    local group=()
    group+=("$_username:x:1000:")
    printf '%s\n' "${group[@]}" | _unshare tee -a "${pacstrap_dir}/etc/group" >/dev/null

    local _autologin_conf="$pacstrap_dir/etc/systemd/system/getty@tty1.service.d/autologin.conf"
    if [[ -e "${_autologin_conf}" ]]; then
        _unshare sed -i "s|%ALTERISO_USERNAME%|${_username}|g" "${_autologin_conf}"
    fi

    echo "${_username} ALL=NOPASSWD: ALL" | _unshare tee -a "$pacstrap_dir/etc/sudoers.d/alteriso_live" >/dev/null

    _msg_info "Done!"
}
