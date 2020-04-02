#!/usr/bin/env bash

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
    done
}


mkdir -p ${HOME}/.config/gtk-3.0/
touch ${HOME}/.config/gtk-3.0/bookmarks

source ${HOME}/.config/user-dirs.dirs

cat > "${HOME}/.config/gtk-3.0/bookmarks" << EOF
file://${XDG_DOCUMENTS_DIR}/
file://${XDG_DOWNLOAD_DIR}/
file://${XDG_MUSIC_DIR}/
file://${XDG_PICTURES_DIR}
file://${XDG_TEMPLATES_DIR}
file://${XDG_VIDEOS_DIR}
EOF

remove ~/.config/autostart/gensidebar.desktop
remove ~/.setup.sh
