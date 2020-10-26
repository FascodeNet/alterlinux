#!/usr/bin/env bash

set -e

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
mode=""
arch=""
channel=""
kernel=""

_help() {
    echo "usage ${0} [options] [command]"
    echo
    echo "Scripts that perform kernel-related processing " 
    echo
    echo " General command:"
    echo "    check [name]       Determine if the kernel is available"
    echo "    show               Shows a list of available kernels"
    echo "    get [name]         Prints the specified kernel settings"
    echo "    help               This help message"
    echo
    echo " General options:"
    echo "    -a | --arch [arch]        Specify the architecture"
    echo "    -c | --channel            Specify the channel"
    echo "    -h | --help               This help message"
}

# Usage: getclm <number>
# 標準入力から値を受けとり、引数で指定された列を抽出します。
getclm() {
    echo "$(cat -)" | cut -d " " -f "${1}"
}

# Message functions
msg_error() {
    "${script_path}/tools/msg.sh" -a "kernel.sh" error "${1}"
}

gen_kernel_list() {
    if [[ -z "${arch}" ]]; then
        msg_error "No architecture specified." 
        exit 1
    fi
    local _list _kernel
    if [[ -n "${channel}" ]] && [[ -f "${script_path}/channels/${channel}/kernel_list-${arch}" ]]; then
        _list="${script_path}/channels/${channel}/kernel_list-${arch}"
    else
        _list="${script_path}/system/kernel-${arch}"
    fi
    for _kernel in $(grep -h -v ^'#' ${_list} | getclm 1); do 
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
        echo "correct"
    else
        echo "incorrect"
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
    _kernel_config_file="${script_path}/system/kernel-${arch}"
    _kernel_name_list=($(cat "${_kernel_config_file}" | grep -h -v ^'#' | getclm 1))
    _get_kernel_line() {
        local _kernel _count=0
        for _kernel in ${_kernel_name_list[@]}; do
            _count=$(( _count + 1 ))
            if [[ "${_kernel}" = "${1}" ]]; then echo "${_count}"; return 0; fi
        done
        echo -n "failed"
        return 0
    }
    _kernel_line="$(_get_kernel_line "${1}")"

    # 不正なカーネル名なら終了する
    if [[ "${_kernel_line}" = "failed" ]]; then
        msg_error "Invalid kernel ${1}"
        exit 1
    fi

    # カーネル設定ファイルから該当の行を抽出
    _kernel_config_line=($(cat "${_kernel_config_file}" | grep -h -v ^'#' | grep -v ^$ | head -n "${_kernel_line}" | tail -n 1))

    # 抽出された行に書かれた設定をそれぞれの変数に代入
    # ここで定義された変数のみがグローバル変数
cat << EOF
kernel="${_kernel_config_line[0]}"
kernel_filename="${_kernel_config_line[1]}"
kernel_mkinitcpio_profile="${_kernel_config_line[2]}"
EOF
}

# Parse options
ARGUMENT="${@}"
_opt_short="a:c:h"
_opt_long="arch:,channel:,help"
OPT=$(getopt -o ${_opt_short} -l ${_opt_long} -- ${ARGUMENT})
[[ ${?} != 0 ]] && exit 1

eval set -- "${OPT}"
unset OPT _opt_short _opt_long

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
    "get"   ) get ${@}      ;;
    "help"  ) _help; exit 0 ;;
    *       ) _help; exit 1 ;;
esac
