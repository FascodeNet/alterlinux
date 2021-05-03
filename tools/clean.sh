#!/usr/bin/env bash

set -eu

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
work_dir="${script_path}/work"
debug=false
only_work=false
noconfirm=false


# 設定ファイルを読み込む
# load_config [file1] [file2] ...
load_config() {
    local _file
    for _file in ${@}; do
        if [[ -f "${_file}" ]]; then
            source "${_file}"
        fi
    done
}

work_dir="$(
    load_config "${script_path}/default.conf"
    load_config "${script_path}/custom.conf"
    cd "${script_path}"
    echo "$(realpath "${work_dir}")"
)"


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

# Show message when file is removed
# remove <file> <file> ...
remove() {
    local _file
    for _file in "${@}"; do msg_debug "Removing ${_file}"; rm -rf "${_file}"; done
}

# Unmount helper Usage: _umount <target>
_umount() { if mountpoint -q "${1}"; then umount -lf "${1}"; fi; }

# Unmount chroot dir
umount_chroot () {
    local _mount
    if [[ ! -v "work_dir" ]] || [[ "${work_dir}" = "" ]]; then
        msg_error "Exception error about working directory" 1
    fi
    if [[ ! -d "${work_dir}" ]]; then
        return 0
    fi
    for _mount in $(find "${build_dir}" -mindepth 1 -type d -printf "%p\0" | xargs -0 -I{} bash -c "mountpoint -q {} && echo {}" | tac | grep -xv "$(realpath -s ${airootfs_dir})"); do
        if echo "${_mount}" | grep "${work_dir}" > /dev/null 2>&1 || echo "${_mount}" | grep "${script_path}" > /dev/null 2>&1 || echo "${_mount}" | grep "${out_dir}" > /dev/null 2>&1; then
            msg_info "Unmounting ${_mount}"
            _umount "${_mount}" 2> /dev/null
        else
            msg_error "It is dangerous to unmount a directory that is not managed by the script."
            msg_error "Path: ${_mount}"
        fi
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

while getopts "dow:hn" arg; do
    case "${arg}" in
        d)  debug=true ;;
        o) only_work=true ;;
        w) work_dir="${OPTARG}" ;;
        n)
            noconfirm=true
            msg_warn "Remove files without warning"
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

if [[ ! -v work_dir ]] && [[ "${work_dir}" = "" ]]; then
    exit 1
fi

if [[ ! "${noconfirm}" = true ]] && (( "$(find "${work_dir}" -type f 2> /dev/null | wc -l)" != 0 )); then
    msg_warn "Forcibly unmount all devices mounted under the following directories and delete them recursively."
    msg_warn "${work_dir}"
    msg_warn -n "Are you sure you want to continue?"
    read -n 1 yesorno
    if [[ "${yesorno}" = "y" ]] || [[ "${yesorno}" = "" ]]; then
        echo
    else
        exit 1
    fi
fi


umount_chroot
if [[ "${only_work}" = false ]]; then
    remove "${script_path}/menuconfig/build/"**
    remove "${script_path}/system/cpp-src/mkalteriso/build"/**
    remove "${script_path}/menuconfig-script/kernel_choice"
    remove "${script_path}/system/mkalteriso"
fi

remove "${work_dir%/}"/**
remove "${work_dir}"
