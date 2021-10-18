#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#
# /lib/locale.sh
#
# Functions for channels
#

# _channel_get_version <channel full path>
# Check alteriso version
_channel_get_version(){
    local _channel
    [[ ! -d "${1}" ]] && return 1
    if [[ ! -f "${1}/alteriso" ]]; then
        #(( $(find "${1}" -maxdepth 1 -mindepth 1 -name "*.x86_64" -o -name ".i686" -o -name "*.any" 2> /dev/null | wc -l) == 0 )) && echo "2.0" && return 0
        _msg_error "Failed to get channel version (\"${1}/alteriso\" was not found)\nIt may be AlterISO 2.0 or lower."
        return 1
    else
        (source "${1}/alteriso"; echo "${alteriso}")
    fi
}

# _channel_check_version <channel full path>
_channel_check_version(){
    #if [[ "$(get_alteriso_version "${1%.add}")" = "${alteriso_version}" ]]; then
    [[ "${nochkver}" = true ]] && return 0
    [[ "$(_channel_get_version "${1}" | cut -d "." -f 1)" = "$(echo "${alteriso_version}" | cut -d "." -f 1)" ]]
}

_channel_check_arch(){
    if [[ -f "${1}/architecture" ]]; then
        grep -h -v ^'#' < "${1}/architecture" | grep -qx "${arch}" || return 1
    fi
    return 0
}

_channel_check_kernel(){
    if [[ -f "${1}/kernel_list-${arch}" ]]; then
        grep -h -v ^'#' < "${1}/kernel_list-${arch}" | grep -qx "${kernel}" || return 1
    fi
    return 0
}

_channel_check_file(){
    [[ ! -e "${1}" ]] && return 1
    (( "$(find "${1}" -mindepth 1 | wc -l)" != 0 ))
}

_channel_full_list() {
    local _dirname _channel_dir
    while read -r _dirname; do
        _channel_dir="${script_path}/channels/${_dirname}"
        [[ -e "${_channel_dir}.add" ]] && continue
        { _channel_check_file "${_channel_dir}" && _channel_check_version "${_channel_dir}"; } && echo "${_channel_dir}"
    done < <(find "${script_path}/channels" -mindepth 1 -maxdepth 1 -printf "%f\n")
}

_channel_path_to_name(){
    xargs -I{} basename {} | sed "s|.add$||g" | sort
}

_channel_name_full_list(){
    _channel_full_list | _channel_path_to_name
}

_channel_checked_list(){
    while read -r _channel_dir; do
        _channel_check_arch "${_channel_dir}" || continue
        _channel_check_kernel "${_channel_dir}" || continue
        echo "${_channel_dir}"
    done < <(_channel_full_list)
}

_channel_name_checked_list(){
    _channel_checked_list | _channel_path_to_name
}

# _channel_check <channel name or channel dir>
# This function returns only exit code. Means is following.
# 0: Correct
# 1: Correct (Unmanaged directory)
# 2: Incorrect
_channel_check() {
    if ! grep -q "/" <<< "${1}"; then
        _channel_checked_list | grep -qx "${script_path}/channels/${1}" && return 0
        return 2
    fi

    _channel_check_file "${1}" || return 2
    _channel_check_arch "${1}" || return 2
    _channel_check_version "${1}" || return 2
    ! grep -qx "${script_path}/channels" < <(realpath "${1}")  || return 1
    return 0
}

_channel_desc() {
    _channel_check_file "${1}" || return 1
    if ! _channel_check_version "${1}" && [[ "${nochkver}" = false ]]; then
        "${script_path}/tools/msg.sh" --noadjust -l 'ERROR:' --noappname error "Not compatible with AlterISO3"
    elif [[ -f "${1}/description.txt" ]]; then
        echo -e "$(cat "${1}/description.txt")"
    else
        "${script_path}/tools/msg.sh" --noadjust -l 'WARN :' --noappname warn "This channel does not have a description.txt"
    fi
}
