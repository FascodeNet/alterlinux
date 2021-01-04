#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2020 Fascode Network.
#
set -e -u

aur_username="aurbuild"


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
cat <<EOF >/aurbuild_temp/setup_yay.sh
#!/usr/bin/env bash
cd /aurbuild_temp
git clone --depth 1 https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -cs
yes | sudo pacman -U *.pkg.*

EOF
chmod 777 /aurbuild_temp/setup_yay.sh
chown ${aur_username}:${aur_username} -R "/aurbuild_temp"
if [ ! -d /etc/sudoers.d ]; then
    mkdir -p /etc/sudoers.d
fi
echo "${aur_username} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/aurbuild"

# Setup keyring
pacman-key --init
#eval $(cat "/etc/systemd/system/pacman-init.service" | grep 'ExecStart' | sed "s|ExecStart=||g" )
ls "/usr/share/pacman/keyrings/"*".gpg" | sed "s|.gpg||g" | xargs | pacman-key --populate


# Build and install
chmod +s /usr/bin/sudo
sudo -u aurbuild /aurbuild_temp/setup_yay.sh
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
        --config "/etc/alteriso-pacman.conf" \
        --cachedir "/var/cache/pacman/pkg/" \
        ${*}


# remove user and file
userdel aurbuild
remove /aurbuild_temp
remove /etc/sudoers.d/aurbuild
remove "/etc/alteriso-pacman.conf"
remove "/var/cache/pacman/pkg/"

yay -Sccc --noconfirm
yay -Syy
