#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#
set -e -u

aur_username="aurbuild"

trap 'exit 1' 1 2 3 15

# Show message when file is removed
# remove <file> <file> ...
remove() {
    local _file
    for _file in "${@}"; do echo "Removing ${_file}" >&2; rm -rf "${_file}"; done
}

# user_check <name>
function user_check () {
    if [[ ! -v 1 ]]; then return 2; fi
    getent passwd "${1}" > /dev/null
}

# Creating a aur user.
if ! user_check "${aur_username}"; then
    useradd -m -d "/aurbuild_temp" "${aur_username}"
fi
mkdir -p "/aurbuild_temp"
chmod 700 -R "/aurbuild_temp"
chown ${aur_username}:${aur_username} -R "/aurbuild_temp"
echo "${aur_username} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/aurbuild"

# Setup keyring
pacman-key --init
pacman-key --populate

# Un comment the mirror list.
#sed -i "s/#Server/Server/g" "/etc/pacman.d/mirrorlist"

# Install yay
if ! pacman -Qq yay 1> /dev/null 2>&1; then
    (
        _oldpwd="$(pwd)"
        pacman -Syy --noconfirm --config "/etc/alteriso-pacman.conf"
        pacman --noconfirm -S --asdeps --needed go --config "/etc/alteriso-pacman.conf"
        sudo -u "${aur_username}" git clone "https://aur.archlinux.org/yay.git" "/tmp/yay"
        cd "/tmp/yay"
        sudo -u "${aur_username}" makepkg --ignorearch --clean --cleanbuild --force --skippgpcheck --noconfirm
        pacman --noconfirm --config "/etc/alteriso-pacman.conf" -U $(sudo -u "${aur_username}" makepkg --packagelist)
        cd ..
        rm -rf "/tmp/yay"
        cd "${_oldpwd}"
    )
fi

if ! type -p yay > /dev/null; then
    echo "Failed to install yay"
    exit 1
fi


# Build and install
chmod +s /usr/bin/sudo
for _pkg in "${@}"; do
    yes | sudo -u "${aur_username}" \
        yay -Sy \
            --mflags "-AcC" \
            --aur \
            --noconfirm \
            --nocleanmenu \
            --nodiffmenu \
            --noeditmenu \
            --noupgrademenu \
            --noprovides \
            --removemake \
            --useask \
            --color always \
            --mflags "--skippgpcheck" \
            --config "/etc/alteriso-pacman.conf" \
            --cachedir "/var/cache/pacman/pkg/" \
            "${_pkg}"

    if ! pacman -Qq "${_pkg}" > /dev/null 2>&1; then
        echo -e "\n[aur.sh] Failed to install ${_pkg}\n"
        exit 1
    fi
done

yay -Sccc --noconfirm --config "/etc/alteriso-pacman.conf"

# remove user and file
userdel "${aur_username}"
remove /aurbuild_temp
remove /etc/sudoers.d/aurbuild
remove "/etc/alteriso-pacman.conf"
remove "/var/cache/pacman/pkg/"
