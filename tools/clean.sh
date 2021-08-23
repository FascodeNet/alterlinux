#!/usr/bin/env bash

set -eu

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
work_dir="${script_path}/work"
tools_dir="${script_path}/tools"
debug=false
only_work=false
noconfirm=false
nocolor=false


# 設定ファイルを読み込む
# load_config [file1] [file2] ...
load_config() {
    local _file
    for _file in "${@}"; do
        if [[ -f "${_file}" ]]; then
            source "${_file}"
        fi
    done
}

work_dir="$(
    load_config "${script_path}/default.conf"
    load_config "${script_path}/custom.conf"
    cd "${script_path}"
    realpath "${work_dir}"
)"

# msg_common [type] [-n] [string]
msg_common(){
    local _msg_opts=("-a" "clean.sh") _msg_type="${1}" && shift 1
    [[ "${1}" = "-n" ]] && _msg_opts+=("-o" "-n") && shift 1
    [[ "${nocolor}" = true ]] && _msg_opts+=("-n")
    "${script_path}/tools/msg.sh" "${_msg_opts[@]}" "${_msg_type[@]}" "${1}"
    [[ -n "${2:-}" ]] && exit "${2}"
    return 0
}

# Show colored message
# $1: message string
# $2: exit code number
msg_info() { msg_common info "${@}"; }
msg_warn() { msg_common warn "${@}"; }
msg_debug() { [[ "${debug}" = true ]] && msg_common debug "${@}"; return 0; }
msg_error() { msg_common error "${@}"; }

# Show message when file is removed
# remove <file> <file> ...
remove() {
    local _file
    for _file in "${@}"; do msg_debug "Removing ${_file}"; rm -rf "${_file}"; done
}

# Unmount helper Usage: _umount <target>
_umount() { if mountpoint -q "${1}"; then umount -lf "${1}"; fi; }

# Unmount chroot dir
#umount_chroot () { "${tools_dir}/umount.sh" -d "${work_dir}" -m 3 "$([[ "${nocolor}" = true ]] && printf "%s" "--nocolor")"; }
umount_chroot () { "${tools_dir}/umount.sh" "${work_dir}" -m 3 "$([[ "${nocolor}" = true ]] && printf "%s" "--nocolor")" "$([[ "${debug}" = true ]] && printf "%s" "-d")"; }

# Usage: getclm <number>
# 標準入力から値を受けとり、引数で指定された列を抽出します。
getclm() { cut -d " " -f "${1}"; }

_help() {
    echo "usage ${0} [option]"
    echo
    echo "Outputs colored messages" 
    echo
    echo " General options:"
    echo "    -d | --debug             Show debug message"
    echo "    -o | --only-work         Remove only work dir"
    echo "    -w | --work [dir]        Specify the work dir"
    echo "    -h | --help              This help message"
    echo "         --nocolor           No output color message"
    echo "         --noconfirm         Clean up without confirmation"
}

# Parse options
# Parse options
ARGUMENT=("${@}")
OPTS=("d" "o" "w:" "h" "n")
OPTL=("help" "nocolor" "noconfirm" "work:" "only-work")
if ! OPT=$(getopt -o "$(printf "%s," "${OPTS[@]}")" -l "$(printf "%s," "${OPTL[@]}")" --  "${ARGUMENT[@]}"); then
    exit 1
fi
eval set -- "${OPT}"
unset OPTS OPTL

while true; do
    case "${1}" in
        -d | --debug)
            debug=true
            shift 1
            ;;
        -o | --only-work)
            only_work=true
            shift 1
            ;;
        -w | --work)
            work_dir="${2}"
            shift 2
            ;;
        -n | --noconfirm)
            noconfirm=true
            msg_warn "Remove files without warning"
            shift 1
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
            shift 1
            break
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

# Check root.
if (( ! "${EUID}" == 0 )); then
    msg_error "This script must be run as root." "1"
fi

# Fullpath
work_dir="$(realpath "${work_dir}")"

if [[ ! "${noconfirm}" = true ]] && (( "$(find "${work_dir}" -type f 2> /dev/null | wc -l)" != 0 )); then
    msg_warn "Forcibly unmount all devices mounted under the following directories and delete them recursively."
    msg_warn "${work_dir}"
    msg_info "Press Enter to continue or Ctrl + C to cancel."
    read -r
fi


umount_chroot
if [[ "${only_work}" = false ]]; then
    remove "${script_path}/menuconfig/build/"**
    remove "${script_path}/menuconfig-script/kernel_choice"
fi

remove "${work_dir%/}"/**
remove "${work_dir}"
