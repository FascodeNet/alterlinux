#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2020 Fascode Network.
#
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
if [[ $(user_check aurbuild) = false ]]; then
    useradd -m -d "/aurbuild_temp" aurbuild
fi
mkdir -p "/aurbuild_temp"
chmod 700 -R "/aurbuild_temp"
chown aurbuild:aurbuild -R "/aurbuild_temp"
echo "aurbuild ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/aurbuild"


# Build and install
remove "/aurbuild_temp/aur_prepare.sh"
for _aur_pkg in ${*}; do
    echo  "cd ~ ; git clone https://aur.archlinux.org/${_aur_pkg}.git" > "/aurbuild_temp/aur_prepare.sh"
    chmod 777 "/aurbuild_temp/aur_prepare.sh"
    sudo -u aurbuild "/aurbuild_temp/aur_prepare.sh"
done