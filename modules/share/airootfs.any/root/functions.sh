#!/usr/bin/env bash

# Check whether true or false is assigned to the variable.
function check_bool() {
    local
    case $(eval echo '$'${1}) in
        true | false) : ;;
                   *) echo "The value ${boot_splash} set is invalid" >&2 ;;
    esac
}

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

# Create a user.
# create_user <username> <password>
function create_user () {
    local _password
    local _username

    _username=${1}
    _password=${2}

    set +u
    if [[ -z "${_username}" ]]; then
        echo "User name is not specified." >&2
        return 1
    fi
    if [[ -z "${_password}" ]]; then
        echo "No password has been specified." >&2
        return 1
    fi
    set -u

    if ! user_check "${_username}"; then
        useradd -m -s ${usershell} ${_username}
        groupadd sudo
        usermod -U -g ${_username} ${_username}
        usermod -aG sudo ${_username}
        usermod -aG storage ${_username}
        cp -aT /etc/skel/ /home/${_username}/
    fi
    chmod 700 -R /home/${_username}
    chown ${_username}:${_username} -R /home/${_username}
    echo -e "${_password}\n${_password}" | passwd ${_username}
    set -u
}

# systemctl helper
# Execute the subcommand only when the specified unit is available.
# Usage: _systemd_service <systemctl subcommand> <service1> <service2> ...
_systemd_service(){
    local _service _command="${1}"
    shift 1
    for _service in "${@}"; do
        # https://unix.stackexchange.com/questions/539147/systemctl-check-if-a-unit-service-or-target-exists
        if (( "$(systemctl list-unit-files "${_service}" | wc -l)" > 3 )); then
            systemctl ${_command} "${_service}"
        else
            echo "${_service} was not found" >&2
        fi
    done
}
