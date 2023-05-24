#!/usr/bin/env bash

load_config() {
    local _file
    for _file in "${@}"; do
        [[ -e "${_file}" ]] && source "${_file}"
        msg_debug "The settings have been overwritten by the ${_file}"
    done
    return 0
}

make_channel(){
    # Load channel config
    load_config "${channel_dir}/config.any" "${channel_dir}/config.${arch}"
    
}
