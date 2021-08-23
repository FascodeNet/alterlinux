#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#
# keyring.sh
#
# Script to import Alter Linux and ArchLinux keys.
#


set -e

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
arch="$(uname -m)"
archlinux32_repo="http://mirror.juniorjpdj.pl/archlinux32/i486/core/"

# Set pacman.conf when build alterlinux
alter_pacman_conf_x86_64="${script_path}/system/pacman-x86_64.conf"
alter_pacman_conf_i686="${script_path}/system/pacman-i686.conf"

# Message common function
# msg_common [type] [-n] [string]
msg_common(){
    local _msg_opts=("-a" "keyring.sh") _type="${1}"
    shift 1
    [[ "${1}" = "-n" ]] && _msg_opts+=("-o" "-n") && shift 1
    _msg_opts+=("${_type}" "${@}")
    "${script_path}/tools/msg.sh" "${_msg_opts[@]}"
}

# Show an INFO message
# ${1}: message string
msg_info() { msg_common info "${@}"; }

# Show an Warning message
# ${1}: message string
msg_warn() { msg_common warn "${@}"; }

# Show an ERROR message then exit with status
# ${1}: message string
# ${2}: exit code number (with 0 does not exit)
msg_error() {
    msg_common error "${1}"
    [[ -n "${2:-}" ]] && exit "${2}"
    return 0
}

# Usage: getclm <number>
# 標準入力から値を受けとり、引数で指定された列を抽出します。
getclm() { cut -d " " -f "${1}"; }


# Show usage
_usage () {
    echo "usage ${0} [options]"
    echo
    echo " General options:"
    echo "    -a | --alter-add       Add alterlinux-keyring."
    echo "    -r | --alter-remove    Remove alterlinux-keyring."
    echo "    -c | --arch-add        Add archlinux-keyring."
    echo "    -h | --help            Show this help and exit."
    echo "    -l | --arch32-add      Add archlinux32-keyring."
    echo "    -i | --arch32-remove   Remove archlinux32-keyring."
    exit "${1}"
}


# Check if the package is installed.
checkpkg() {
    local _pkg
    _pkg=$(echo "${1}" | cut -d'/' -f2)

    if [[ ${#} -gt 2 ]]; then
        msg_error "Multiple package specification is not available."
    fi

    if [[ -n $( pacman -Q "${_pkg}" 2> /dev/null| getclm 1 ) ]]; then
        echo -n "true"
    else
        echo -n "false"
    fi
}


run() {
    msg_info "Running ${*}"
    eval "${@}"
}


prepare() {
    if [[ ! ${UID} = 0 ]]; then
        msg_error "You dont have root permission."
        msg_error 'Please run as root.'
        exit 1
    fi

    if [[ ! -f "${alter_pacman_conf_x86_64}" ]]; then
        msg_error "${alter_pacman_conf_x86_64} does not exist."
        exit 1
    fi

    if [[ ! -f "${alter_pacman_conf_i686}" ]]; then
        msg_error "${alter_pacman_conf_i686} does not exist."
        exit 1
    fi

    pacman -Sc --noconfirm > /dev/null 2>&1
    pacman -Syy
}


update_arch_key() {
    pacman-key --refresh-keys
    pacman-key --init
    pacman-key --populate archlinux
    pacman -Sy --noconfirm core/archlinux-keyring
    pacman-key --init
    pacman-key --populate archlinux
}


update_alter_key() {
    curl -Lo - "http://repo.dyama.net/fascode.pub" \
        | pacman-key -a -
    pacman-key --lsign-key development@fascode.net

    pacman --config "${alter_pacman_conf_x86_64}" -Sy --noconfirm alter-stable/alterlinux-keyring

    pacman-key --init
    pacman-key --populate alterlinux
}


remove_alter_key() {
    pacman-key -d BDC396346243AB57ACD090F9F50544048389DA36
    if checkpkg alterlinux-keyring; then
        pacman -Rsnc --noconfirm alterlinux-keyring
    fi
}

update_arch32_key() {
    ! pacman -Ssq archlinux32-keyring | grep -x archlinux32-keyring 2> /dev/null 1>&2 && msg_error "Not found archlinux32-keyring on remote repository. You should install it manually." 1
    pacman --noconfirm -S archlinux32-keyring
    pacman-key --init
    pacman-key --populate archlinux32
    #pacman-key --refresh-keys
}

new_update_arch32_key(){
    local _savedir="${HOME}/.cache"
    while read -r _pkg ; do
        curl -o "${_savedir}/${_pkg}" "${archlinux32_repo}/${_pkg}"
        pacman -U --noconfirm "${_savedir}/${_pkg}"
        rm -f "${_savedir}/${_pkg}"
    done < <(curl -sL "${archlinux32_repo}" | sed "s|<a href=\"||g" | cut -d "\"" -f 1 | grep -v "^<" | grep -v ".sig$" | grep ".pkg.tar." | grep "archlinux32-keyring" | grep -v "archlinux32-keyring-transition")
    pacman-key --init
    pacman-key --populate archlinux32
}

remove_arch32_key() {
    pacman -Rsnc archlinux32-keyring
}


# 引数解析
while getopts 'archli-:' arg; do
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
        # arch32-add
        l)
            run prepare
            run update_arch32_key
            ;;
        # arch32-remove
        i)
            run prepare
            run remove_arch32_key
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
                arch32-add)
                    run prepare
                    run update_arch32_key
                    ;;
                arch32-remove)
                    run prepare
                    run remove_arch32_key
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
    run update_arch32_key
fi
