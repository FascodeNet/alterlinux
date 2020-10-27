#!/usr/bin/env bash

set -e

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
mode=""
arch=""
channel=""
locale=""

_help() {
    echo "usage ${0} [options] [command]"
    echo
    echo "Scripts that perform locale-related processing " 
    echo
    echo " General command:"
    echo "    check [name]       Determine if the locale is available"
    echo "    show               Shows a list of available locales"
    echo "    get [name]         Prints the specified locale settings"
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
    "${script_path}/tools/msg.sh" -a "locale.sh" error "${1}"
}

gen_locale_list() {
    if [[ -z "${arch}" ]]; then
        msg_error "No architecture specified." 
        exit 1
    fi
    local _locale
    for _locale in $(grep -h -v ^'#' "${script_path}/system/locale-${arch}" | getclm 1); do 
        localelist+=("${_locale}")
    done
}

check() {
    gen_locale_list
    if [[ ! "${#}" = "1" ]]; then
        _help
        exit 1
    fi
    if [[ $(printf '%s\n' "${localelist[@]}" | grep -qx "${1}"; echo -n ${?} ) -eq 0 ]]; then
        echo "correct"
    else
        echo "incorrect"
    fi
}

show() {
    gen_locale_list
    if (( "${#localelist[*]}" > 0)); then
        echo "${localelist[*]}"
    fi
}

get() {
    gen_locale_list
    if [[ ! "${#}" = "1" ]]; then
        _help
        exit 1
    fi

    #-- ロケールを解析、設定 --#
    local _get_locale_line_number _locale_config_file _locale_name_list _locale_line_number _locale_config_line

    # 選択されたロケールの設定が描かれた行番号を取得
    _locale_config_file="${script_path}/system/locale-${arch}"
    _locale_name_list=($(cat "${_locale_config_file}" | grep -h -v ^'#' | awk '{print $1}'))
    _get_locale_line_number() {
        local _lang _count=0
        for _lang in ${_locale_name_list[@]}; do
            _count=$(( _count + 1 ))
            if [[ "${_lang}" = "${1}" ]]; then echo "${_count}"; return 0; fi
        done
        echo -n "failed"
    }
    _locale_line_number="$(_get_locale_line_number ${@})"

    # 不正なロケール名なら終了する
    if [[ "${_locale_line_number}" = "failed" ]]; then
        msg_error "${1} is not a valid language."
        exit 1
    fi

    # ロケール設定ファイルから該当の行を抽出
    _locale_config_line=($(cat "${_locale_config_file}" | grep -h -v ^'#' | grep -v ^$ | head -n "${_locale_line_number}" | tail -n 1))

    # 抽出された行に書かれた設定をそれぞれの変数に代入
    # ここで定義された変数のみがグローバル変数
    cat << EOF
locale_name="${_locale_config_line[0]}"
locale_gen_name="${_locale_config_line[1]}"
locale_version="${_locale_config_line[2]}"
locale_time="${_locale_config_line[3]}"
locale_fullname="${_locale_config_line[4]}"
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
