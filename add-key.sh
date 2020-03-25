#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascone.net
#
# (c) 2019-2020 Fascode Network.
#
# add-key.sh
#
# Script to import AlterLinux and ArchLinux keys.
#

set -eu

script_path="$(readlink -f ${0%/*})"

alter_pacman_conf="${script_path}/system/pacman.conf"


msg_error() {
    echo -e "[add-key.sh] ERROR : ${@}" >&2
}

msg_info() {
    echo -e "[add-key.sh] INFO: ${@}" >&1
}


_usage () {
    echo "usage ${0} [options]"
    echo
    echo " General options:"
    echo "    --alter            Add alterlinux-keyring."
    echo "    --arch             Add archlinux-keyring"
}


checkpkg() {
    local _pkg
    _pkg=$(echo "${@}" | cut -d'/' -f2)

    if [[ -n $( pacman -Q "${_pkg}" 2> /dev/null| awk '{print $1}' ) ]]; then
        echo -n "true"
    else
        echo -n "false"
    fi
}


_pacman_install() {
    for i in ${@}; do
        if [[ $(checkpkg "${i}") = false ]]; then
            pacman -S --noconfirm "${i}"
        fi
    done
}


run() {
    msg_info "Running ${@}"
    ${@}
}


prepare() {
    if [[ ! ${UID} = 0 ]]; then
        msg_error "You dont have root permission."
        msg_error 'Please run as root.'
        exit 1
    fi

    if [[ ! -f "${alter_pacman_conf}" ]]; then
        msg_error "${alter_pacman_conf} does not exist."
        exit 1
    fi
}


update_arch_key() {
    pacman-key --init
    pacman-key --populate archlinux
    _pacman_install core/archlinux-keyring
    pacman-key --refresh-keys
}


update_system() {
    pacman -Syy
}


upgrade_system() {
    pacman -Syu
}


updae_alter_key() {
    curl -L -o "/tmp/fascode.pub" "https://山d.com/repo/fascode.pub"
    pacman-key -a "/tmp/fascode.pub"
    rm -f "/tmp/fascode.pub"
    pacman-key --lsign-key development@fascode.net

    pacman --config "${alter_pacman_conf}" -Syy --noconfirm
    pacman --config "${alter_pacman_conf}" -S --noconfirm alter-stable/alterlinux-keyring

    pacman-key --init
    pacman-key --populate alterlinux
}


while getopts 'h-:' arg; do
    case "${arg}" in
        h) _usage ;;
        -)
            case "${OPTARG}" in
                alter)
                    run prepare
                    run updae_alter_key
                    ;;
                arch)
                    run prepare
                    run update_arch_key
                    ;;
                system)
                    run prepare
                    run update_system
                    run upgrade_system
                    ;;
                help) _usage ;;
            esac
            ;;
    esac
done


if [[ ${#} = 0 ]]; then
    run prepare
    run update_arch_key
    run update_system
    run updae_alter_key
    run update_system
fi