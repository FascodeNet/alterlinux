#!/usr/bin/env bash
# shellcheck disable=SC2154

__alteriso_lightdm_validate() {
    local _username
    _username=$(__alteriso_profiledef_username)
    if [[ -z "$_username" || "$_username" == "null" ]]; then
        echo "[alteriso] ERROR: The lightdm module requires a non-empty username." >&2
        exit 1
    fi
}

__alteriso_add_validator __alteriso_lightdm_validate

__alteriso_lightdm_replace_username() {
    local _username
    _username=$(__alteriso_profiledef_username)

    # Replace auto login user
    sed -i "s|%USERNAME%|${_username}|g" "$pacstrap_dir/etc/lightdm/lightdm.conf.d/02-autologin.conf"
}

__alteriso_lightdm_session_customizable() {
    local _target_conf="$pacstrap_dir/etc/lightdm/lightdm.conf.d/02-autologin-session.conf"
    if [[ ! -e "${_target_conf}" ]]; then
        return 1
    fi
    grep -q "%SESSION%" "${_target_conf}"
}

__alteriso_lightdm_detect_session() {
    local _session_list=()
    while read -r session; do
        _session_list+=("${session}")
    done < <(find "$pacstrap_dir/usr/share/xsessions" -type f -print0 -name "*.desktop" | xargs -0 -I{} bash -c 'basename {} | sed "s|.desktop||g"')

    if (("${#_session_list[@]}" == 1)); then
        echo "${_session_list[*]}"
        return 0
    elif (("${#_session_list[@]}" == 0)); then
        return 2
    else
        return 3
    fi
}

__alteriso_lightdm_replace_session() {

    __alteriso_lightdm_session_customizable || return 0

    local _target_conf="$pacstrap_dir/etc/lightdm/lightdm.conf.d/02-autologin-session.conf"
    local _session
    if ! _session=$(__alteriso_lightdm_detect_session); then
        case $? in
            2)
                echo "Warning: Auto login session was not found" >&2
                ;;
            3)
                echo "Failed to set the session. Multiple sessions were found." >&2
                echo "Please set the session of automatic login in ${_target_conf}" >&2
                echo "Found session: $(printf "%s " "${_session_list[@]}")" >&2
                sleep 0.5
                exit 1
                ;;
        esac
    else
        sed -i "s|%SESSION%|${_session}|g" "${_target_conf}"
    fi
}

__alteriso_lightdm_setup_autologin() {
    __alteriso_new_group "autologin"
    __alteriso_add_user_to_group "$(__alteriso_profiledef_username)" "autologin"
}

__alteriso_lightdm_disable_getty_autologin() {
    local _autologin_conf="$pacstrap_dir/etc/systemd/system/getty@tty1.service.d/autologin.conf"
    if [[ -e "${_autologin_conf}" ]]; then
        rm -f "${_autologin_conf}"
    fi
}
__alteriso_lightdm_customize_airootfs() {
    __alteriso_lightdm_replace_username
    __alteriso_lightdm_replace_session
    __alteriso_lightdm_disable_getty_autologin
    __alteriso_lightdm_setup_autologin
}
