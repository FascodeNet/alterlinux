#!/usr/bin/env bash

set -e

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
mode=""
arch=""
channel=""
kernel=""
script=false

_help() {
    echo "usage ${0} [options] [command]"
    echo
    echo "Scripts that perform kernel-related processing " 
    echo
    echo " General command:"
    echo "    check [name]              Determine if the kernel is available"
    echo "    show                      Shows a list of available kernels"
    echo "    get [name]                Prints the specified kernel settings"
    echo "    help                      This help message"
    echo
    echo " General options:"
    echo "    -a | --arch [arch]        Specify the architecture"
    echo "    -c | --channel            Specify the channel"
    echo "    -s | --script             Enable script mode"
    echo "    -h | --help               This help message"
    echo
    echo " Script mode usage:"
    echo "     check                    Returns 0 if the check was successful, 1 otherwise."
    printf '     get                      eval $(%s -s -a <arch> -c <channel> get <kernel>)\n' "$(basename "${0}")"
}

# Usage: getclm <number>
# 標準入力から値を受けとり、引数で指定された列を抽出します。
getclm() { cut -d " " -f "${1}"; }

# Message functions
msg_error() {
    "${script_path}/tools/msg.sh" -s 6 -a "kernel.sh" error "${1}"
}

gen_kernel_list() {
    if [[ -z "${arch}" ]]; then
        msg_error "No architecture specified." 
        exit 1
    fi
    local _list _kernel
    if [[ -n "${channel}" ]] && [[ -f "${script_path}/channels/${channel}/kernel_list-${arch}" ]]; then
        _list="${script_path}/channels/${channel}/kernel_list-${arch}"
    elif [[ -n "${channel}" ]] && [[ -f "${script_path}/channels/${channel}/kernel-${arch}" ]]; then
        _list="${script_path}/channels/${channel}/kernel-${arch}"
    else
        _list="${script_path}/system/kernel-${arch}"
    fi
    for _kernel in $(grep -h -v ^'#' "${_list}" | getclm 1); do 
        kernellist+=("${_kernel}")
    done
}

check() {
    gen_kernel_list
    if [[ ! "${#}" = "1" ]]; then
        _help
        exit 1
    fi
    if [[ $(printf '%s\n' "${kernellist[@]}" | grep -qx "${1}"; echo -n ${?} ) -eq 0 ]]; then
        #echo "correct"
        exit 0
    else
        #echo "incorrect"
        exit 1
    fi
}

show() {
    gen_kernel_list
    if (( "${#kernellist[*]}" > 0)); then
        echo "${kernellist[*]}"
    fi
}

get() {
    gen_kernel_list
    if [[ ! "${#}" = "1" ]]; then
        _help
        exit 1
    fi

    #-- カーネルを解析、設定 --#
    local _kernel_config_file _kernel_name_list _kernel_line _get_kernel_line _kernel_config_line

    # 選択されたカーネルの設定が描かれた行番号を取得
    if [[ -n "${channel}" ]] && [[ -f "${script_path}/channels/${channel}/kernel-${arch}" ]]; then
        _kernel_config_file="${script_path}/channels/${channel}/kernel-${arch}"
    else
        _kernel_config_file="${script_path}/system/kernel-${arch}"
    fi
    readarray -t _kernel_name_list < <(grep -h -v ^'#' "${_kernel_config_file}" | grep -v ^$  | getclm 1)
    _get_kernel_line() {
        local _kernel _count=0
        for _kernel in "${_kernel_name_list[@]}"; do
            _count=$(( _count + 1 ))
            [[ "${_kernel}" = "${1}" ]] && echo "${_count}" && return 0
        done
        echo -n "failed"
        return 1
    }
    _kernel_line="$(_get_kernel_line "${1}")"

    # 不正なカーネル名なら終了する
    if [[ "${_kernel_line}" = "failed" ]]; then
        msg_error "Invalid kernel ${1}"
        if [[ "${script}" = true ]]; then
            echo "exit 1"
        fi
        exit 1
    fi

    # カーネル設定ファイルから該当の行を抽出
    readarray -t _kernel_config_line < <(grep -h -v ^'#' "${_kernel_config_file}" | grep -v ^$ | head -n "${_kernel_line}" | tail -n 1 | sed -e 's/  */ /g' | tr " " "\n")

    # 抽出された行に書かれた設定をそれぞれの変数に代入
    # ここで定義された変数のみがグローバル変数
cat << EOF
kernel="${_kernel_config_line[0]}"
kernel_filename="${_kernel_config_line[1]}"
kernel_mkinitcpio_profile="${_kernel_config_line[2]}"
EOF
}

# Parse options
OPTS="a:c:hs"
OPTL="arch:,channel:,help,script"
if ! OPT=$(getopt -o ${OPTS} -l ${OPTL} -- "${@}"); then
    exit 1
fi
eval set -- "${OPT}"
unset OPT OPTS OPTL

while true; do
    case ${1} in
        -a | --arch)
            arch="${2}"
            shift 2
            ;;
        -c | --channel)
            channel="${2}"
            shift 2
            ;;
        -s | --script)
            script=true
            shift 1
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
    "check" ) check "${@}"  ;;
    "show"  ) show          ;;
    "get"   ) get "${@}"    ;;
    "help"  ) _help; exit 0 ;;
    *       ) _help; exit 1 ;;
esac
