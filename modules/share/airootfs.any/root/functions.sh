#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#
# functions.sh
#
# bash functions for customize_airootfs.sh
#


# Check whether true or false is assigned to the variable.
function check_bool() {
    local
    case $(eval echo '$'"${1}") in
        true | false) : ;;
                   *) echo "The value ${boot_splash} set is invalid" >&2 ;;
    esac
}

# Show message when file is removed
# remove <file> <file> ...
remove() {
    local _file
    for _file in "${@}"; do echo "Removing ${_file}"; rm -rf "${_file}"; done
}

# user_check <name>
function user_check () {
    if [[ ! -v 1 ]]; then return 2; fi
    getent passwd "${1}" > /dev/null
}

# Execute only if the command exists
# run_additional_command [command name] [command to actually execute]
run_additional_command() {
    if [[ -f "$(type -p "${1}" 2> /dev/null)" ]]; then
        shift 1
        eval "${@}"
    fi
}


function installedpkg () {
    if pacman -Qq "${1}" 1>/dev/null 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Add group if it does not exist
_groupadd(){
    cut -d ":" -f 1 < "/etc/group" | grep -qx "${1}" && return 0 || groupadd "${1}"
}

# Create a user.
# create_user <username> <password>
function create_user () {
    local _username="${1-""}" _password="${2-""}"

    if [[ -z "${_username}" ]]; then
        echo "User name is not specified." >&2
        return 1
    fi
    if [[ -z "${_password}" ]]; then
        echo "No password has been specified." >&2
        return 1
    fi

    if ! user_check "${_username}"; then
        useradd -m -s "${usershell}" "${_username}"
        _groupadd sudo
        usermod -U -g "${_username}" "${_username}"
        usermod -aG sudo "${_username}"
        usermod -aG storage "${_username}"
        cp -aT "/etc/skel/" "/home/${_username}/"
    fi
    chmod 700 -R "/home/${_username}"
    chown "${_username}:${_username}" -R "/home/${_username}"
    echo -e "${_password}\n${_password}" | passwd "${_username}"
    set -u
}

# systemctl helper
# Execute the subcommand only when the specified unit is available.
# Usage: _safe_systemctl <systemctl subcommand> <service1> <service2> ...
_safe_systemctl(){
    local _service _command="${1}"
    shift 1
    for _service in "${@}"; do
        if [[ "${_command}" = "enable" ]] && [[ "$(systemctl is-enabled "${_service}")" = "enabled" ]]; then
            echo "${_service} has been enabled" >&2
            continue
        fi
        systemctl "${_command}" "${_service}" || true
    done
    return 0
}
