#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#
# umount.sh
#
# Simple script to unmmount everything under the specified directory
#

set -eu

declare target_dir
script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
tools_dir="${script_path}/tools/"
debug=false
nocolor=false
force=false
maxdepth="2"

_help() {
    echo "usage ${0} [options] [dir]"
    echo
    echo "Unmount everything under the specified directory" 
    echo
    echo " General options:"
    echo "    -f | --force              Force umount (No warning)"
    echo "    -d | --debug              Enable debug message"
    echo "    -m | --maxdepth           Specify the maximum hierarchy (set 0 to no limit)"
    echo "    -h | --help               This help message"
    echo "         --nocolor            No output color message"
}

# Message common function
# msg_common [type] [-n] [string]
msg_common(){
    local _msg_opts=("-a" "umount.sh" "--label-space" "6") _type="${1}"
    shift 1
    [[ "${1}" = "-n" ]] && _msg_opts+=("-o" "-n") && shift 1
    [[ "${nocolor}"  = true ]] && _msg_opts+=("-n")
    _msg_opts+=("${_type}" "${@}")
    "${tools_dir}/msg.sh" "${_msg_opts[@]}" &
}

# Show an INFO message
# ${1}: message string
msg_info() { msg_common info "${@}"; }

# Show an Warning message
# ${1}: message string
msg_warn() { msg_common warn "${@}"; }

# Show an debug message
# ${1}: message string
msg_debug() { 
    [[ "${debug}" = true ]] && msg_common debug "${@}"
    return 0
}

# Show an ERROR message then exit with status
# ${1}: message string
# ${2}: exit code number (with 0 does not exit)
msg_error() {
    msg_common error "${1}"
    [[ -n "${2:-}" ]] && exit "${2}"
}

# Unmount helper Usage: _umount <target>
_umount() { if mountpoint -q "${1}"; then umount -lf "${1}"; fi; }

# Unmount work dir
umount_work () {
    local _mount
    if [[ ! -v "target_dir" ]] || [[ "${target_dir}" = "" ]]; then
        msg_error "Exception error about working directory" 1
    fi
    [[ ! -d "${target_dir}" ]] && return 0
    while read -r _mount; do
        if [[ "${force}" = true ]] || [[ "${_mount}" = "${target_dir}"* ]] > /dev/null 2>&1; then
            msg_debug "Checking ${_mount}"
            if mountpoint -q "${_mount}"; then
                msg_info "Unmounting ${_mount}"
                _umount "${_mount}" 2> /dev/null
            fi
        else
            msg_error "It is dangerous to unmount a directory that is not managed by the script."
        fi
    done < <(
        if (( maxdepth == 0 )); then
            find "${target_dir}" -mindepth 1 -type d -printf "%p\n" | tac
        else
            find "${target_dir}" -mindepth 1 -maxdepth "${maxdepth}" -type d -printf "%p\n" | tac
        fi
    )
}


# Parse options
OPTS=("d" "f" "h" "m:")
OPTL=("debug" "force" "help" "maxdepth:" "nocolor")
if ! OPT=$(getopt -o "$(printf "%s," "${OPTS[@]}")" -l "$(printf "%s," "${OPTL[@]}")" --  "${@}"); then
    exit 1
fi

eval set -- "${OPT}"
msg_debug "Argument: ${OPT}"
unset OPT OPTS OPTL

while true; do
    case "${1}" in
        -d | --debug)
            debug=true
            shift 1
            ;;
        -f | --force)
            force=true
            shift 1
            ;;
        -m | --maxdepth)
            maxdepth="${2}"
            shift 2
            ;;
        -h | --help)
            _help
            exit 0
            ;;
        --nocolor)
            nocolor=true
            shift 1
            ;;
        --)
            shift
            break
            ;;
        *)
            msg_error "Invalid argument '${1}'"
            _help
            exit 1
            ;;
    esac
done

# Check root.
if (( ! "${EUID}" == 0 )); then
    msg_error "This script must be run as root." "1"
fi


if [[ -z "${1+SET}" ]]; then
    msg_error "Please specify the target directory." "1"
else
    target_dir="$(realpath "${1}")"
fi

umount_work
