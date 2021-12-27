#!/usr/bin/env bash

set -e

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
mode=""
arch=""
channel=""
locale=""
script=false

_help() {
    echo "usage ${0} [options] [command]"
    echo
    echo "Scripts that perform locale-related processing " 
    echo
    echo " General command:"
    echo "    check [name]              Determine if the locale is available"
    echo "    show                      Shows a list of available locales"
    echo "    get [name]                Prints the specified locale settings"
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
    printf '     get                      eval $(%s -s -a <arch> -c <channel> get <locale>)\n' "$(basename ${0})"
}

# Usage: getclm <number>
# 標準入力から値を受けとり、引数で指定された列を抽出します。
getclm() { cut -d " " -f "${1}"; }

# Message functions
msg_error() {
    "${script_path}/tools/msg.sh" -s 6 -a "locale.sh" error "${1}"
}

gen_locale_list() {
    if [[ -z "${arch}" ]]; then
        msg_error "No architecture specified." 
        exit 1
    fi
    if [[ ! -f "${script_path}/system/locale-${arch}" ]]; then
        msg_error "Missing architecture ${arch}"
        exit 1
    fi
    local _locale
    for _locale in $(grep -h -v ^'#' "${script_path}/system/locale-${arch}" | grep -v ^$ | getclm 1); do 
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
        #echo "correct"
        exit 0
    else
        #echo "incorrect"
        exit 1
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
    readarray -t _locale_name_list < <(grep -h -v ^'#' "${_locale_config_file}" | grep -v ^$ | awk '{print $1}')
    _get_locale_line_number() {
        local _lang _count=0
        for _lang in "${_locale_name_list[@]}"; do
            _count=$(( _count + 1 ))
            if [[ "${_lang}" = "${1}" ]]; then echo "${_count}"; return 0; fi
        done
        echo -n "failed"
    }
    _locale_line_number="$(_get_locale_line_number "${@}")"

    # 不正なロケール名なら終了する
    if [[ "${_locale_line_number}" = "failed" ]]; then
        msg_error "${1} is not a valid language."
        if [[ "${script}" = true ]]; then
            echo "exit 1"
        fi
        exit 1
    fi

    # ロケール設定ファイルから該当の行を抽出
    readarray -t _locale_config_line < <(grep -h -v ^'#' "${_locale_config_file}" | grep -v ^$ | head -n "${_locale_line_number}" | tail -n 1 | tail -n 1 | sed -e 's/  */ /g' | tr " " "\n")

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
OPTS="a:c:hs"
OPTL="arch:,channel:,help,script"
if ! OPT=$(getopt -o ${OPTS} -l ${OPTL} -- "${@}"); then
    exit 1
fi
eval set -- "${OPT}"
unset OPTS OPTL

while true; do
    case "${1}" in
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
    "check" ) check "${@}"    ;;
    "show"  ) show          ;;
    "get"   ) get "${@}"      ;;
    "help"  ) _help; exit 0 ;;
    *       ) _help; exit 1 ;;
esac
