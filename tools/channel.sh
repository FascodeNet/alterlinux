#!/usr/bin/env bash

set -e

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
opt_only_add=false
opt_dir_name=false
opt_nochkver=false
opt_nobuiltin=false
opt_fullpath=false
opt_nocheck=false
opt_line=false
alteriso_version="3.1"
mode=""
arch="all"
kernel="all"

_help() {
    echo "usage ${0} [options] [command]"
    echo
    echo "The script that performs processing related to channels" 
    echo
    echo " General command:"
    echo "    check [name]       Returns whether the specified channel name is valid."
    echo "    desc [name]        Display a description of the specified channel"
    echo "    show               Display a list of channels"
    echo "    ver                Display a version declared on the channel"
    echo "    help               This help message"
    echo
    echo " General options:"
    echo "    -a | --arch [arch]        Specify the architecture"
    echo "    -b | --nobuiltin          Exclude built-in channels"
    echo "    -d | --dirname            Display directory names of all channel as it is"
    echo "    -f | --fullpath           Display the full path of the channel (Use with -db)"
    echo "    -k | --kernel [name]      Specify the supported kernel"
    echo "    -n | --nochkver           Ignore channel version"
    echo "    -o | --only-add           Only additional channels"
    echo "    -v | --version [ver]      Specifies the AlterISO version"
    echo "    -h | --help               This help message"
    echo
    echo "         --nocheck            Do not check the channel with desc command.This option helps speed up."
    echo "         --line               Line break the output"
    echo
    echo " check command exit code"
    echo "    0 (correct)               Normal available channel"
    echo "    1 (directory)             Channel outside the channel directory"
    echo "    2 (incorrect)             Unavailable channel"
    echo "    3                         Other error"
}

gen_channel_list() {
    local _dirname
    for _dirname in $(ls -l "${script_path}"/channels/ | awk '$1 ~ /d/ {print $9}'); do
        if [[ -n $(ls "${script_path}"/channels/${_dirname}) ]] && check_alteriso_version "${_dirname}/" || [[ "${opt_nochkver}" = true ]]; then
            if [[  ! "${arch}" = "all" ]] && [[ -z "$(cat "${script_path}/channels/${_dirname}/architecture" 2> /dev/null | grep -h -v ^'#' | grep -x "${arch}")" ]]; then
                continue
            elif [[ ! "${kernel}" = "all" ]] && [[ -f "${channel_dir}/kernel_list-${arch}" ]] && [[ -z $( ( cat "${script_path}/channels/${_dirname}/kernel_list-${arch}" | grep -h -v ^'#' | grep -x "${kernel}" ) 2> /dev/null) ]]; then
                continue
            elif [[ $(echo "${_dirname}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
                if [[ "${opt_dir_name}" = true ]]; then
                    if [[ "${opt_fullpath}" = true ]]; then
                        channellist+=("${script_path}/channels/${_dirname}/")
                    else
                        channellist+=("${_dirname}")
                    fi
                else
                    #channellist+=("$(echo ${_dirname} | sed 's/\.[^\.]*$//')")
                    readarray -t -O "${#channellist[@]}" channellist < <(echo "${_dirname}" | sed 's/\.[^\.]*$//')
                fi
            elif [[ ! -d "${script_path}/channels/${_dirname}.add" ]] && [[ "${opt_only_add}" = false ]]; then
                if [[ "${opt_fullpath}" = true ]]; then
                    channellist+=("${script_path}/channels/${_dirname}/")
                else
                    channellist+=("${_dirname}")
                fi
            else
                continue
            fi
        fi
    done
    if [[ "${opt_nobuiltin}" = false ]]; then
        channellist+=("clean")
    fi
}

# check?alteriso_version <channel dir>
get_alteriso_version(){
    local _channel
    if [[ ! -d "${script_path}/channels/${1}" ]]; then
        _channel="${script_path}/channels/${1}.add"
    else
        _channel="${script_path}/channels/${1}"
    fi
    if [[ ! -d "${_channel}" ]]; then
        echo "${1} was not found." >&2
        exit 1
    fi
    if [[ ! -f "${_channel}/alteriso" ]]; then
        if (( $(find ./ -maxdepth 1 -mindepth 1 -name "*.x86_64" -o -name ".i686" -o -name "*.any" 2> /dev/null | wc -l) == 0 )); then
            echo "2.0"
        fi
    else
        echo "$(
            source "${_channel}/alteriso"
            echo "${alteriso}"
        )"
    fi
}

check_alteriso_version(){
    #if [[ "$(get_alteriso_version "${1%.add}")" = "${alteriso_version}" ]]; then
    if [[ "$(get_alteriso_version "${1%.add}" | cut -d "." -f 1)" = "$(echo "${alteriso_version}" | cut -d "." -f 1)" ]]; then
        return 0
    else
        return 1
    fi
}

check() {
    local _channel_name

    gen_channel_list
    if [[ ! "${#}" = "1" ]]; then
        _help
        exit 3
    fi
    if [[ $(printf '%s\n' "${channellist[@]}" | grep -qx "${1}"; echo -n ${?} ) -eq 0 ]]; then
        #echo "correct"
        exit 0
    elif [[ -d "${1}" ]] && [[ -n $(ls "${1}") ]]; then
        _channel_name="$(basename "${1%/}")"
        if check_alteriso_version "${_channel_name}" || [[ "${opt_nochkver}" = true ]]; then
            #echo "directory"
            exit 1
        else
            #echo "incorrect"
            exit 2
        fi
    else
        #echo "incorrect"
        exit 2
    fi
}

desc() {
    #gen_channel_list
    if [[ ! "${#}" = "1" ]]; then
        _help
        exit 1
    fi
    if [[ "${opt_nocheck}" = false ]] && ! bash "${script_path}/tools/channel.sh" -a ${arch} -n -b check "${1}"; then
        exit 1
    fi
    local _channel
    if [[ ! -d "${script_path}/channels/${1}" ]]; then
        _channel="${1}.add"
    else
        _channel="${1}"
    fi
    if ! check_alteriso_version "${_channel}" && [[ "${opt_nochkver}" = false ]]; then
        "${script_path}/tools/msg.sh" --noadjust -l 'ERROR:' --noappname error "Not compatible with AlterISO3"
    elif [[ -f "${script_path}/channels/${_channel}/description.txt" ]]; then
        echo -ne "$(cat "${script_path}/channels/${_channel}/description.txt")\n"
    else
        "${script_path}/tools/msg.sh" --noadjust -l 'WARN :' --noappname warn "This channel does not have a description.txt"
    fi
}

show() {
    gen_channel_list
    if (( "${#channellist[*]}" > 0)); then
        if [[ "${opt_line}" = true ]]; then
            printf "%s\n" "${channellist[@]}"
        else
            echo "${channellist[*]}"
        fi
    fi
}


# Parse options
OPTS="a:bdfk:nov:h"
OPTL="arch:,nobuiltin,dirname,fullpath,kernel:,only-add,nochkver,version:,help,nocheck,line"
if ! OPT=$(getopt -o ${OPTS} -l ${OPTL} -- "${@}"); then
    exit 1
fi
eval set -- "${OPT}"
unset OPT OPTS OPTL

while true; do
    case "${1}" in
        -a | --arch)
            arch="${2}"
            shift 2
            ;;
        -b | --nobuiltin)
            opt_nobuiltin=true
            shift 1
            ;;
        -d | --dirname)
            opt_dir_name=true
            shift 1
            ;;
        -f | --fullpath)
            opt_fullpath=true
            shift 1
            ;;
        -k | --kernel)
            kernel="${2}"
            shift 2
            ;;
        -n | --nochkver)
            opt_nochkver=true
            shift 1
            ;;
        -o | --only-add)
            opt_only_add=true
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
        --nocheck)
            opt_nocheck=true
            shift 1
            ;;
        --line)
            opt_line=true
            shift 1
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
    "check" ) check "${@}"                ;;
    "show"  ) show                        ;;
    "desc"  ) desc "${@}"                 ;;
    "ver"   ) get_alteriso_version "${@}" ;;
    "help"  ) _help; exit 0               ;;
    *       ) _help; exit 1               ;;
esac
