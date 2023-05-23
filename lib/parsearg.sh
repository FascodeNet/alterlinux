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

# ロングオプションと代入先の変数名
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
    ["noiso"]="noiso"
    ["noefi"]="noefi"
)

_err_unknown(){
    msg_err "Unknown argument: $1"
    exit 1
}

_err_noarg(){
    msg_err "Missing argument: $1"
    exit 1
}

parsearg(){
    local _args=("$@") _noarg=()
    local _current="" _arg="" _var="" _setarg=false
    while [[ -n "${1-""}" ]]; do
        _current="$1" _arg="$2" _var="" _setarg=false

        if [[ "$_current" = "--" ]]; then
            shift 1
            _noarg=("$@")
            break
        fi

        if [[ "$_current" = "-"* ]] && ! [[ "$_current" = "--"* ]]; then
            _current="${_current#"-"}"
            local _shorts=()
            readarray -t _shorts < <(grep -o . <<< "$_current") # 1文字ずつsplit


            # 連結したショートオプションを分解
            for _s in "${_shorts[@]}"; do
                # 定義されている場合
                local _p="${short_alias["${_s}"]}" # エイリアス置き換え

                # エイリアスが存在しているなら
                if [[ -n "${_p-""}"  ]]; then
                    if [[ -n "${long_option_arg["$_p"]}" ]]; then
                        _var="${long_option_arg["$_p"]}"

                        # 連結したショートオプションの末尾
                        if [[ "$_current" = *"$_s" ]] && ! [[ "$_arg" = "-"* ]]; then
                            _setarg=true
                        else
                            _err_noarg "-${_s}"
                        fi
                    elif [[ -n "${long_option_noarg["$_p"]}" ]]; then
                        _var="${long_option_noarg["$_p"]}"
                        _setarg=false
                    else
                        _err_unknown "-${_s}"
                    fi

                    # 変数を設定
                    if [[ "$_setarg" = true ]]; then
                        printf -v "$_var" "%s" "$_arg"
                        shift 2
                    else
                        printf -v "$_var" true
                        shift 1
                    fi
                else
                    _err_unknown "-${_s}"
                fi
            done

            continue
        fi

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

            continue
        fi

        _noarg+=("$1")
        shift 1
    done
    
    printf "%s\n" "${_noarg[@]}"
}
