#!/usr/bin/env bash

make_pacmanconf(){
    # Pacman configuration file used only when building
    # If there is pacman.conf for each channel, use that for building
    local _use="" _pacman_conf=""
    local _pacman_conf_list=(
        "${script_path}/pacman-${arch}.conf"
        "${channel_dir}/pacman-${arch}.conf"
        "${script_path}/system/pacman-conf/pacman-${arch}.conf")
    for _pacman_conf in "${_pacman_conf_list[@]}"; do
        if [[ -f "${_pacman_conf}" ]]; then
            _use="${_pacman_conf}"
            break
        fi
    done

    if [[ -z "${_use}" ]]; then
        msg_err "There is no pacman.conf"
        exit 1
    fi

    msg_debug "Use $_use as pacman.conf"

    # Todo: Change cache_dir

    cp "$_use" "$work_dir/profile/pacman.conf"
}
