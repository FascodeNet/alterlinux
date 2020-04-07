#!/usr/bin/env bash

set -e -u


# Default value
# All values can be changed by arguments.
password=alter
boot_splash=false
kernel=core
theme_name=alter-logo
rebuild=false
japanese=false
username='alter'
os_name="Alter Linux"


# Parse arguments
while getopts 'p:bt:k:rxju:o:' arg; do
    case "${arg}" in
        p) password="${OPTARG}" ;;
        b) boot_splash=true ;;
        t) theme_name="${OPTARG}" ;;
        k) kernel="${OPTARG}" ;;
        r) rebuild=true ;;
        j) japanese=true;;
        u) username="${OPTARG}" ;;
        o) os_name="${OPTARG}" ;;
        x) set -xv ;;
    esac
done


# Delete file only if file exists
# remove <file1> <file2> ...
function remove () {
    local _list
    local _file
    _list=($(echo "$@"))
    for _file in "${_list[@]}"; do
        if [[ -f ${_file} ]]; then
            rm -f "${_file}"
        elif [[ -d ${_file} ]]; then
            rm -rf "${_file}"
        fi
        echo "${_file} was deleted."
    done
}


# Delete icon cache
if [[ -f /home/${username}/.cache/icon-cache.kcache ]]; then
    rm /home/${username}/.cache/icon-cache.kcache
fi


# Disable services.
# To disable start up of sddm.
# If it is enable, Users have to enter password.
#systemctl disable sddm
#if [[ ${boot_splash} = true ]]; then
#    systemctl disable sddm-plymouth.service
#fi