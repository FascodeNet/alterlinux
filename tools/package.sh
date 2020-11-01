#!/usr/bin/env bash

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"

verbose=false
script_mode=false

# Show an INFO message
# $1: message string
msg_info() {
    local _msg_opts="-a package.sh"
    if [[ "${1}" = "-n" ]]; then
        _msg_opts="${_msg_opts} -o -n"
        shift 1
    fi
    "${script_path}/tools/msg.sh" ${_msg_opts} info "${1}"
}

# Show an Warning message
# $1: message string
msg_warn() {
    local _msg_opts="-a package.sh"
    if [[ "${1}" = "-n" ]]; then
        _msg_opts="${_msg_opts} -o -n"
        shift 1
    fi
    "${script_path}/tools/msg.sh" ${_msg_opts} warn "${1}"
}

# Show an verbose message
# $1: message string
msg_verbose() {
    if [[ "${verbose}" = true ]]; then
        local _msg_opts="-a package.sh"
        if [[ "${1}" = "-n" ]]; then
            _msg_opts="${_msg_opts} -o -n"
            shift 1
        fi
        "${script_path}/tools/msg.sh" ${_msg_opts} verbose "${1}"
    fi
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
msg_error() {
    local _msg_opts="-a package.sh"
    if [[ "${1}" = "-n" ]]; then
        _msg_opts="${_msg_opts} -o -n"
        shift 1
    fi
    "${script_path}/tools/msg.sh" ${_msg_opts} error "${1}"
    if [[ -n "${2:-}" ]]; then
        exit ${2}
    fi
}

# rm helper
# Delete the file if it exists.
# For directories, rm -rf is used.
# If the file does not exist, skip it.
# remove <file> <file> ...
remove() {
    local _list=($(echo "$@")) _file
    for _file in "${_list[@]}"; do
        if [[ -f ${_file} ]]; then
            msg_info "Removing ${_file}"
            rm -f "${_file}"
        elif [[ -d ${_file} ]]; then
            msg_info "Removing ${_file}"
            rm -rf "${_file}"
        fi
    done
}

# Usage: getclm <number>
# 標準入力から値を受けとり、引数で指定された列を抽出します。
getclm() {
    echo "$(cat -)" | cut -d " " -f "${1}"
}

_help() {
    echo "usage ${0} [option] [package]"
    echo
    echo "Check the status of the specified package"
    echo
    echo " General options:"
    #echo "    -v                       Enable verbose message"
    #echo "    -s                       Enable script mode"
    echo "    -h                       This help message"
    echo
    echo " Script mode output:"
    echo "    latest                   The latest package is installed"
    echo "    noversion                Failed to get the latest version of the package, but the package is installed"
    echo "    old                      Older version is installed"
    echo "    failed                   Package not installed"
}

while getopts "hv" arg; do
    case ${arg} in
        v)
            verbose=true
            ;;
        h) 
            _help
            exit 0
            ;;
        *)
            _help
            exit 1
            ;;
    esac
done

shift $((OPTIND - 1))


 _installed_pkg=($(pacman -Q | getclm 1))
 _installed_ver=($(pacman -Q | getclm 2))

for pkg in $(seq 0 $(( ${#_installed_pkg[@]} - 1 ))); do
    # パッケージがインストールされているかどうか
    if [[ "${_installed_pkg[${pkg}]}" = ${1} ]]; then
        ver="$(pacman -Sp --print-format '%v' ${1} 2> /dev/null; :)"
        if [[ "${_installed_ver[${pkg}]}" = "${ver}" ]]; then
            # パッケージが最新の場合
            echo "latest"
        elif [[ -z "${ver}" ]]; then
            # リモートのバージョンの取得に失敗した場合
            echo "noversion"
        else
            # リモートとローカルのバージョンが一致しない場合
            echo "old"
        fi
    fi
done
[[ "${verbose}" = true ]] && echo
msg_error "failed"
