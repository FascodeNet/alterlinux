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

# user_check <name>
function user_check () {
    if [[ $(getent passwd $1 > /dev/null ; printf $?) = 0 ]]; then
        if [[ -z $1 ]]; then
            echo -n "false"
        fi
        echo -n "true"
    else
        echo -n "false"
    fi
}

# Creating a aur user.
if [[ $(user_check ${aur_username}) = false ]]; then
    useradd -m -d "/aurbuild_temp" "${aur_username}"
fi
mkdir -p "/aurbuild_temp"
chmod 700 -R "/aurbuild_temp"
chown ${aur_username}:${aur_username} -R "/aurbuild_temp"
echo "${aur_username} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/aurbuild"

# Setup keyring
pacman-key --init
#eval $(cat "/etc/systemd/system/pacman-init.service" | grep 'ExecStart' | sed "s|ExecStart=||g" )
ls "/usr/share/pacman/keyrings/"*".gpg" | sed "s|.gpg||g" | xargs | pacman-key --populate

# Un comment the mirror list.
sed -i "s/#Server/Server/g" "/etc/pacman.d/mirrorlist"

# Install yay
if ! pacman -Qq yay 1> /dev/null 2>&1; then
    (
        _oldpwd="$(pwd)"
        pacman -Syy --noconfirm --config "/etc/alteriso-pacman.conf"
        pacman --noconfirm -S --asdeps --needed go --config "/etc/alteriso-pacman.conf"
        sudo -u aurbuild git clone "https://aur.archlinux.org/yay.git" "/tmp/yay"
        cd "/tmp/yay"
        sudo -u aurbuild makepkg --ignorearch --clean --cleanbuild --force --skippgpcheck --noconfirm
        pacman --noconfirm --config "/etc/alteriso-pacman.conf" -U $(sudo -u aurbuild makepkg --packagelist)
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
    yes | sudo -u aurbuild \
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
userdel aurbuild
remove /aurbuild_temp
remove /etc/sudoers.d/aurbuild
remove "/etc/alteriso-pacman.conf"
remove "/var/cache/pacman/pkg/"
