#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascone.net
#
# (c) 2019-2020 Fascode Network.
#
# keyring.sh
#
# Script to import AlterLinux and ArchLinux keys.
#


set -eu

script_path="$(readlink -f ${0%/*})"


# Set pacman.conf when build alterlinux
alter_pacman_conf="${script_path}/system/pacman.conf"


# erro message
msg_error() {
    echo -e "[keyring.sh] ERROR : ${@}" >&2
}


# info message
msg_info() {
    echo -e "[keyring.sh] INFO: ${@}" >&1
}


# Show usage
_usage () {
    echo "usage ${0} [options]"
    echo
    echo " General options:"
    echo "    -a | --alter-add     Add alterlinux-keyring."
    echo "    -r | --alter-remove  Remove alterlinux-keyring."
    echo "    -c | --arch-add      Add archlinux-keyring."
    echo "    -h | --help          Show this help and exit."
    exit "${1}"
}


# Check if the package is installed.
checkpkg() {
    local _pkg
    _pkg=$(echo "${1}" | cut -d'/' -f2)

    if [[ ${#} -gt 2 ]]; then
        msg_error "Multiple package specification is not available."
    fi

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
    #pacman -Sy
}


update_arch_key() {
    pacman-key --init
    pacman-key --populate archlinux
    _pacman_install core/archlinux-keyring
    pacman-key --refresh-keys
    pacman -Sy
}


update_alter_key() {
    curl -L -o "/tmp/fascode.pub" "https://山d.com/repo/fascode.pub"
    pacman-key -a "/tmp/fascode.pub"
    rm -f "/tmp/fascode.pub"
    pacman-key --lsign-key development@fascode.net

    pacman --config "${alter_pacman_conf}" -Sy --noconfirm
    pacman --config "${alter_pacman_conf}" -S --noconfirm alter-stable/alterlinux-keyring

    pacman-key --init
    pacman-key --populate alterlinux
    pacman -Sy
}


remove_alter_key() {
    pacman-key -d BDC396346243AB57ACD090F9F50544048389DA36
    if checkpkg alterlinux-keyring; then
        pacman -Rsnc --noconfirm alterlinux-keyring
    fi
    pacman -Sy
}


# 引数解析
while getopts 'arch-:' arg; do
    case "${arg}" in
        # alter-add
        a)
            run prepare
            run update_alter_key
            ;;
        # alter-remove
        r)
            run prepare
            run remove_alter_key
            ;;
        # arch-add
        c)
            run prepare
            run update_arch_key
            ;;
        # help
        h) 
            _usage 0
            ;;
        -)
            case "${OPTARG}" in
                alter-add)
                    run prepare
                    run update_alter_key
                    ;;
                alter-remove)
                    run prepare
                    run remove_alter_key
                    ;;
                arch-add)
                    run prepare
                    run update_arch_key
                    ;;
                help)
                    _usage 0
                    ;;
                *)
                    _usage 1
                    ;;
            esac
            ;;
	*) _usage; exit 1;;
    esac
done


# 引数が何もなければ全てを実行する
if [[ ${#} = 0 ]]; then
    run prepare
    # run update_arch_key
    run update_alter_key
fi
