#!/usr/bin/env bash

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
work_dir="${script_path}/work"
debug=false
only_work=false

# Show an INFO message
# $1: message string
msg_info() {
    local _msg_opts="-a clean.sh"
    if [[ "${1}" = "-n" ]]; then
        _msg_opts="${_msg_opts} -o -n"
        shift 1
    fi
    "${script_path}/tools/msg.sh" ${_msg_opts} info "${1}"
}

# Show an Warning message
# $1: message string
msg_warn() {
    local _msg_opts="-a clean.sh"
    if [[ "${1}" = "-n" ]]; then
        _msg_opts="${_msg_opts} -o -n"
        shift 1
    fi
    "${script_path}/tools/msg.sh" ${_msg_opts} warn "${1}"
}

# Show an debug message
# $1: message string
msg_debug() {
    if [[ "${debug}" = true ]]; then
        local _msg_opts="-a clean.sh"
        if [[ "${1}" = "-n" ]]; then
            _msg_opts="${_msg_opts} -o -n"
            shift 1
        fi
        "${script_path}/tools/msg.sh" ${_msg_opts} debug "${1}"
    fi
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
msg_error() {
    local _msg_opts="-a clean.sh"
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
            msg_info "Removeing ${_file}"
            rm -f "${_file}"
        elif [[ -d ${_file} ]]; then
            msg_info "Removeing ${_file}"
            rm -rf "${_file}"
        fi
    done
}

# Unmount chroot dir
umount_chroot () {
    local _mount
    for _mount in $(mount | getclm 3 | grep $(realpath ${work_dir}) | tac); do
        msg_info "Unmounting ${_mount}"
        umount -lf "${_mount}" 2> /dev/null
    done
}

# Usage: getclm <number>
# 標準入力から値を受けとり、引数で指定された列を抽出します。
getclm() {
    echo "$(cat -)" | cut -d " " -f "${1}"
}

_help() {
    echo "usage ${0} [option]"
    echo
    echo "Outputs colored messages" 
    echo
    echo " General options:"
    echo "    -d                       Show debug message"
    echo "    -o                       Remove only work dir"
    echo "    -w [dir]                 Specify the work dir"
    echo "    -h                       This help message"
}

while getopts "dw:h" arg; do
    case ${arg} in
        d)  debug=true ;;
        o) only_work=true ;;
        w) work_dir="${OPTARG}" ;;
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

msg_debug "ほげえ"

umount_chroot
if [[ "${only_work}" = false ]]; then
    remove "${script_path}/menuconfig/build/"**
    remove "${script_path}/system/cpp-src/mkalteriso/build"/**
    remove "${script_path}/menuconfig-script/kernel_choice"
    remove "${script_path}/system/mkalteriso"
fi
remove "${work_dir%/}"/**
remove "${work_dir}"
