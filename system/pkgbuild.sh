#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#
set -e

build_username="pkgbuild"


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

# Usage: get_srcinfo_data <path> <var>
# 参考: https://qiita.com/withelmo/items/b0e1ffba639dd3ae18c0
get_srcinfo_data() {
    local _srcinfo="${1}" _ver="${2}"
    local _srcinfo_json=$(python << EOF
from srcinfo.parse import parse_srcinfo; import json
text = """
$(cat ${1})
"""
parsed, errors = parse_srcinfo(text)
print(json.dumps(parsed))
EOF
)
    echo "${_srcinfo_json}" | jq -rc "${2}" | tr '\n' ' '
}

# Creating a user for makepkg
if [[ $(user_check ${build_username}) = false ]]; then
    useradd -m -d "/pkgbuild_temp" "${build_username}"
fi
mkdir -p "/pkgbuild_temp"
chmod 700 -R "/pkgbuild_temp"
chown ${build_username}:${build_username} -R "/pkgbuild_temp"
echo "${build_username} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/pkgbuild"

# Setup keyring
pacman-key --init
#eval $(cat "/etc/systemd/system/pacman-init.service" | grep 'ExecStart' | sed "s|ExecStart=||g" )
ls "/usr/share/pacman/keyrings/"*".gpg" | sed "s|.gpg||g" | xargs | pacman-key --populate


# Parse SRCINFO
if [[ -z "${1}" ]]; then
    echo "Please specify the directory that contains PKGBUILD." >&2
    exit 1
fi
chown "${build_username}" -R "${1}"
chmod 775 -R "${1}"
cd "${1}"
makedepends=() depends=()
for _dir in *; do
    cd "${_dir}"
    sudo -u "${build_username}" bash -c "makepkg --printsrcinfo > .SRCINFO"
    makedepends+=($(get_srcinfo_data ".SRCINFO" ".makedepends[]?"))
    depends+=($(get_srcinfo_data ">SRCINFO" ".depends[]?"))
    cd - >/dev/null
done

# Build and install
chmod +s /usr/bin/sudo
yes | sudo -u "${build_username}" \
    yay -Sy \
        --mflags "-AcC" \
        --asdeps \
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
        ${makedepends[*]} ${depends[*]}

for _dir in *; do
    cd "${_dir}"
    sudo -u "${build_username}" makepkg -iAcC
    cd - >/dev/null
done

pacman -Rsnc $(pacman -Qtdq)

yay -Sccc --noconfirm --config "/etc/alteriso-pacman.conf"

# remove user and file
userdel "${build_username}"
remove "/pkgbuild_temp"
remove "/etc/sudoers.d/pkgbuild"
remove "/etc/alteriso-pacman.conf"
remove "/var/cache/pacman/pkg/"


