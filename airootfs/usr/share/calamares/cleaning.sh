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

cat > /etc/skel/.config/gtk-3.0/bookmarks << EOF
file:///home/${user}/Pictures
file:///home/${user}/etc/skel/.config/gtk-3.0/bookmarks/Videos
file:///home/${user}/Templates
file:///home/${user}/Music
file:///home/${user}/Downloads
file:///home/${user}/Documents
EOF

cp /etc/skel/.config/gtk-3.0/bookmarks /home/${user}/.config/gtk-3.0/bookmarks