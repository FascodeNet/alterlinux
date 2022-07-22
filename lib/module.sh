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
# Functions for module
#

_module_get_alteriso(){
    [[ -f "${module_dir}/${1}/alteriso" ]] || (
        echo 0
    ) && (
        source "${module_dir}/${1}/alteriso"
        echo "${alteriso}"
        unset alteriso
    )
}

_module_check(){
    local _version
    
    { (( "${#}" == 0 )) || (( "${#}" >= 2 )); } && return 2
    (( "$(_module_get_alteriso "${1}" | cut -d "." -f 1)" == "$(echo "${alteriso_version}" | cut -d "." -f 1)" )) && return 0
    return 1
}

_module_check_with_msg(){
    _msg_debug -n "Checking ${1} module ... "
    _module_check "${1}" || ([[ "${debug}" = true ]] && echo; _msg_error "Module ${1} is not available." "1" )&& msg_debug "Load ${module_dir}/${1}"
}

_module_list(){
    local _module _name _version _list=()
    while read -r _module; do
        _module_check "${_module}" && _list+=("${_module}")
    done < <(find "${module_dir}" -maxdepth 2 -mindepth 2 -type f -name "alteriso" -print0 | xargs -0I{} dirname {} | xargs -I{} basename {})
    printf "%s\n" "${_list[@]}"
}
