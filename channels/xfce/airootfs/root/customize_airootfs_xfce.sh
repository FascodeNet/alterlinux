#!/usr/bin/env bash

set -e -u

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


# Replace wallpaper.
if [[ -f /usr/share/backgrounds/xfce/xfce-stripes.png ]]; then
    remove /usr/share/backgrounds/xfce/xfce-stripes.png
    ln -s /usr/share/backgrounds/alter.png /usr/share/backgrounds/xfce/xfce-stripes.png
fi
[[ -f /usr/share/backgrounds/alter.png ]] && chmod 644 /usr/share/backgrounds/alter.png