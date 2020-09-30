#!/usr/bin/env bash

set -e

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
opt_only_add=false
opt_dir_name=false
opt_nochkver=false
opt_nobuiltin=false
opt_allarch=false
alteriso_version="3.0"
mode=""

_help() {
    echo "usage ${0} [options] [command]"
    echo
    echo "The script that performs processing related to channels" 
    echo
    echo " General command:"
    echo "    check [name]       Returns whether the specified channel name is valid."
    echo "    show               Display a list of channels"
    echo "    help               This help message"
    echo
    echo " General options:"
    echo "    -a | --add                Only additional channels"
    echo "    -b | --nobuiltin          Exclude built-in channels"
    echo "    -d | --dirname            Display directory names of all channel as it is"
    echo "    -m | --multi              Only channels supported by allarch.sh"
    echo "    -n | --nochkver           Ignore channel version"
    echo "    -v | --version [ver]      Specifies the AlterISO version"
    echo "    -h | --help               This help message"
}

gen_channel_list() {
    local _dirname
    for _dirname in $(ls -l "${script_path}"/channels/ | awk '$1 ~ /d/ {print $9}'); do
        if [[ -n $(ls "${script_path}"/channels/${_dirname}) ]] && [[ "$(cat "${script_path}/channels/${_dirname}/alteriso" 2> /dev/null)" = "alteriso=${alteriso_version}" ]] || [[ "${opt_nochkver}" = true ]]; then
            if [[ "${_dirname}" = "share" ]]; then
                continue
            elif [[ $(echo "${_dirname}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
                if [[ "${opt_dir_name}" = true ]]; then
                    channellist+=("${_dirname}")
                else
                    channellist+=("$(echo ${_dirname} | sed 's/\.[^\.]*$//')")
                fi
            elif [[ ! -d "${script_path}/channels/${_dirname}.add" ]] && [[ "${opt_only_add}" = false ]]; then
                channellist+=("${_dirname}")
            else
                continue
            fi
        fi
    done
    if [[ "${opt_nobuiltin}" = false ]]; then
        if [[ "${opt_allarch}" = false ]]; then
            channellist+=("rebuild")
        fi
        channellist+=("clean")
    fi
}

check() {
    gen_channel_list
    if [[ ! "${#}" = "1" ]]; then
        _help
        exit 1
    fi
    if [[ $(printf '%s\n' "${channellist[@]}" | grep -qx "${1}"; echo -n ${?} ) -eq 0 ]]; then
        echo "true"
    elif [[ -d "${1}" ]]; then
        if [[ -n $(ls "${1}") ]] && [[ "$(cat "${1}/alteriso" 2> /dev/null)" = "alteriso=${alteriso_version}" ]] || [[ "${opt_nochkver}" = true ]]; then
            local _channel_name="$(basename "${1%/}")"
            if [[ ! "${_channel_name}" = "share" ]]; then
                if [[ $(echo "${_channel_name}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]] || [[ ! -d "${script_path}/channels/${_dirname}.add" ]] && [[ "${opt_only_add}" = false ]]; then
                    echo "true"
                fi
            fi
        else
            echo "false"
        fi
    else
        echo "false"
    fi
}

show() {
    gen_channel_list
    echo "${channellist[*]}"
}


# Parse options
ARGUMENT="${@}"
_opt_short="abdmnv:h"
_opt_long="add,nobuiltin,dirname,multi,nochkver,version:,help"
OPT=$(getopt -o ${_opt_short} -l ${_opt_long} -- ${ARGUMENT})
[[ ${?} != 0 ]] && exit 1

eval set -- "${OPT}"
unset OPT _opt_short _opt_long

while true; do
    case ${1} in
        -a | --add)
            opt_only_add=true
            shift 1
            ;;
        -b | --nobuiltin)
            opt_nobuiltin=true
            shift 1
            ;;
        -d | --dirname)
            opt_dir_name=true
            shift 1
            ;;
        -m | --multi)
            opt_allarch=true
            shift 1
            ;;
        -n | --nochkver)
            opt_nochkver=true
            shift 1
            ;;
        -v | --version)
            alteriso_version="${2}"
            shift 2
            ;;
        -h | --help)
            _help
            exit 0
            ;;
        --)
            shift 1
            break
            ;;

    esac
done

if [[ -z "${1}" ]]; then
    _help
    exit 1
else
    mode="${1}"
    shift 1
fi

case "${mode}" in
    "check" ) check ${@}    ;;
    "show"  ) show          ;;
    "help"  ) _help; exit 0 ;;
    *       ) _help; exit 1 ;;
esac
