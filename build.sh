#!/usr/bin/env bash

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && pwd )"
_msg_error() {
    #local _msg="${1}"
    #local _error=${2}
    #printf '[%s] ERROR: %s\n' "${app_name}" "${_msg}" >&2
    #if (( _error > 0 )); then
    #    exit "${_error}"
    #fi

    local _msg_opts="-a build.sh"
    if [[ "${1}" = "-n" ]]; then
        _msg_opts="${_msg_opts} -o -n"
        shift 1
    fi
    [[ "${msgdebug}" = true ]] && _msg_opts="${_msg_opts} -x"
    [[ "${nocolor}"  = true ]] && _msg_opts="${_msg_opts} -n"
    "${script_path}/scripts/msg.sh" ${_msg_opts} error "${1}"
    if [[ -n "${2:-}" ]]; then
        exit ${2}
    fi
}
mkarchiso_argskun=""
while getopts 'p:C:L:P:A:D:w:o:g:vbnh?' arg; do
    case "${arg}" in
        p)
            mkarchiso_argskun = "${mkarchiso_argskun} -p ${OPTARG}"
            ;;
        C) mkarchiso_argskun = "${mkarchiso_argskun} -C ${OPTARG}" ;;
        L) mkarchiso_argskun="${mkarchiso_argskun} -L ${OPTARG}" ;;
        P) mkarchiso_argskun="${mkarchiso_argskun} -P ${OPTARG}" ;;
        A) mkarchiso_argskun="${mkarchiso_argskun} -A ${OPTARG}" ;;
        D) mkarchiso_argskun="${mkarchiso_argskun} -D ${OPTARG}" ;;
        w) mkarchiso_argskun="${mkarchiso_argskun} -w ${OPTARG}" ;;
        o) mkarchiso_argskun="${mkarchiso_argskun} -o ${OPTARG}" ;;
        g) mkarchiso_argskun="${mkarchiso_argskun} -g ${OPTARG}" ;;
        v) mkarchiso_argskun="${mkarchiso_argskun} -v" ;;
        b) mkarchiso_argskun="${mkarchiso_argskun} -b" ;;
        n) mkarchiso_argskun="${mkarchiso_argskun} -n" ;;
        h|?) 
            "${script_path}/archiso/mkarchiso" -h | sed -e "s/profile_dir/channel_dir/g"
            exit 0
            ;;
        *)
            _msg_error "Invalid argument '${arg}'" 0
            "${script_path}/archiso/mkarchiso" -m | sed -e "s/profile_dir/channel_dir/g"
            exit -1
            ;;
    esac
done

shift $((OPTIND - 1))

if (( $# < 1 )); then
    _msg_error "No channel specified" 0
    _usage 1
fi

if (( EUID != 0 )); then
    _msg_error "${app_name} must be run as root." 1
fi

# get the absolute path representation of the first non-option argument
channel="$(realpath -- "${script_path}/channels/${1}")" 
share_dir="$(realpath -- "${script_path}/channels/share")" 
mkarchiso_argskun="${mkarchiso_argskun} -s ${share_dir} ${channel}"
"${script_path}/archiso/mkarchiso" ${mkarchiso_argskun}
