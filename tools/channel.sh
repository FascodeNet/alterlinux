#!/usr/bin/env bash

set -e

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
opt_only_add=false
opt_dir_name=false
opt_nochkver=false
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
    echo "    -a                 Only additional channels"
    echo "    -d                 Display directory names of all channel as it is"
    echo "    -n                 Ignore channel version"
    echo "    -v [ver]           Specifies the AlterISO version"
    echo "    -h                 This help message"
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
    channellist+=("rebuild")
}

check() {
    gen_channel_list
    if [[ ! "${#}" == "1" ]]; then
        _help
        exit 1
    fi
    if [[ $(printf '%s\n' "${channellist[@]}" | grep -qx "${1}"; echo -n ${?} ) -eq 0 ]]; then
        echo "true"
    else
        echo "false"
    fi
}

show() {
    gen_channel_list
    echo "${channellist[*]}"
}

while getopts 'adhnv:' arg; do
    case "${arg}" in
        a) opt_only_add=true ;;
        d) opt_dir_name=true ;;
        n) opt_nochkver=true ;;
        v) alteriso_version="${OPTARG}" ;;
        h) _help ; exit 0 ;;
        *) _help ; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

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
