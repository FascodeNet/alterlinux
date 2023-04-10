#!/usr/bin/env bash

# ショートオプションの定義
declare -A short_alias=(
    ["b"]="boot-splash"
    ["e"]="cleanup"
    ["r"]="tarball"
    ["h"]="help"
    ["a"]="arch"
    ["c"]="comp-type"
    ["g"]="gpgkey"
    ["l"]="lang"
    ["k"]="kernel"
    ["o"]="out"
    ["p"]="password"
    ["t"]="comp-opts"
    ["u"]="user"
    ["w"]="work"
)

# ロングオプションと
declare -A long_option_arg=(
    ["arch"]="arch"
    ["comp-type"]="sfs_comp"
    ["gpgkey"]="gpg_key"
)

declare -A long_option_noarg=(
    ["boot-splash"]="boot_splash"
    ["cleanup"]="cleaning"
    ["cleaning"]="cleaning"
    ["tarball"]="tarball"
    ["help"]="show_help"
)

_err_unknown(){
    msg_err "Unknown argument: $1"
    exit 1
}

_err_noarg(){
    msg_err "Missing argument: $1"
}

parsearg(){
    local _args=("$@")
    local _current="" _arg="" _var="" _setarg=false
    while [[ -n "$1" ]]; do
        _current="$1" _arg="$2" _var="" _setarg=false
        if [[ "$_current" = "--"* ]]; then
            #-- ロングオプション --#
            _current="${_current#"--"}"  # 先頭の--を削除

            # 変数名を取得
            if [[ -n "${long_option_arg["$_current"]}" ]]; then
                _var="${long_option_arg["$_current"]}"
                _setarg=true
            elif [[ -n "${long_option_noarg["$_current"]}" ]]; then
                _var="${long_option_noarg["$_current"]}"
                _setarg=false
            fi

            # 未定義
            if [[ -z "${_var-""}" ]]; then
                _err_unknown "$1"
            elif { [[ -z "${_arg}" ]] && [[ "$_setarg" = true ]]; }; then
                _err_noarg "$1"
            fi

            # 変数を設定
            if [[ "$_setarg" = true ]]; then
                printf -v "$_var" "%s" "$_arg"
                shift 2
            else
                printf -v "$_var" true
                shift 1
            fi
        fi
    done

}
