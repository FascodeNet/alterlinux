#!/usr/bin/env bash

function remove () {
    local list
    local file
    list=($(echo "$@"))
    for file in "${list[@]}"; do
        if [[ -f ${file} ]]; then
            rm -f "${file}"
        elif [[ -d ${file} ]]; then
            rm -rf "${file}"
        fi
    done
}

while getopts 'u:' arg; do
    case "${arg}" in
        u) user="${OPTARG}";;
    esac
done

remove /etc/skel/Desktop
remove /etc/skel/.config/gtk-3.0/bookmarks
remove /home/${user}/Desktop/calamares.desktop
remove /home/${user}/.config/gtk-3.0/bookmarks
remove /etc/systemd/system/getty@tty1.service.d/autologin.conf
remove /root/.automated_script.sh
remove /etc/mkinitcpio-archiso.conf
remove /etc/initcpio

if [[ -f /home/${user}/.config/user-dirs.dirs ]]
    HOME="/home/${user}"
    source ${HOME}/.config/user-dirs.dirs

    # Add pictures to bookmark
    echo -n "file://" >> ${HOME}/.config/user-dirs.dirs
    echo -n "${XDG_PICTURES_DIR}" >> ${HOME}/.config/user-dirs.dirs
    echo -ne "\n" >> ${HOME}/.config/user-dirs.dirs

    # Add videos to bookmark
    echo -n "file://" >> ${HOME}/.config/user-dirs.dirs
    echo -n "${XDG_VIDEOS_DIR}" >> ${HOME}/.config/user-dirs.dirs
    echo -ne "\n" >> ${HOME}/.config/user-dirs.dirs

    # Add music to bookmark
    echo -n "file://" >> ${HOME}/.config/user-dirs.dirs
    echo -n "${XDG_VIDEOS_DIR}" >> ${HOME}/.config/user-dirs.dirs
    echo -ne "\n" >> ${HOME}/.config/user-dirs.dirs

    # Add downloads to bookmark
    echo -n "file://" >> ${HOME}/.config/user-dirs.dirs
    echo -n "${XDG_DOWNLOAD_DIR}" >> ${HOME}/.config/user-dirs.dirs
    echo -ne "\n" >> ${HOME}/.config/user-dirs.dirs

    # Add documents to bookmark
    echo -n "file://" >> ${HOME}/.config/user-dirs.dirs
    echo -n "${XDG_DOCUMENTS_DIR}" >> ${HOME}/.config/user-dirs.dirs
    echo -ne "\n" >> ${HOME}/.config/user-dirs.dirs
fi