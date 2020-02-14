#!/usr/bin/env bash

set -e

function enable_plymouth () {
    local yn
    echo -n "Plymouthを有効化しますか？ （y/N） : "
    read yn
    case ${yn} in
        y | Y | yes | Yes | YES ) plymouth=true   ;;
        n | N | no  | No  | NO  ) plymouth=false  ;;
        *                       ) enable_plymouth ;;
    esac
}

function select_comp_type () {
    local yn
    echo "圧縮方式を以下の番号から選択してください "
    echo
    echo "1: gzip"
    echo "2: lzma"
    echo "3: lzo"
    echo "4: lz4"
    echo "5: xz"
    echo "6: zstd"
    echo -n ": "

    read yn

    case ${yn} in
           1) comp_type="gzip" ;;
           2) comp_type="lzma" ;;
           3) comp_type="lzo"  ;;
           4) comp_type="lz4"  ;;
           5) comp_type="xz"   ;;
           6) comp_type="zstd" ;;
        gzip) comp_type="gzip" ;;
        lzma) comp_type="lzma" ;;
        lzo ) comp_type="lzo"  ;;
        lz4 ) comp_type="lz4"  ;;
        xz  ) comp_type="xz"   ;;
        zstd) comp_type="zstd" ;;
        *) select_comp_type ;;
    esac
}

function set_comp_option () {
    local gzip
    local lzma
    local lzo
    local lz4
    local xz
    local zstd
    comp_option=""

    function zstd () {
        local level
        local exit_code
        echo -n "zstdの圧縮方式を入力してください。 (1~22) : "
        read level
        if [[ ${level} -lt 22 && ${level} -ge 4 ]]; then
            comp_option="-Xcompression-level ${level}"
        else
            zstd
        fi
    }

    case ${comp_type} in
        zstd ) zstd ;;
        *    ) :    ;;
    esac
}

function set_password () {
    echo -n "パスワードを入力してください : "
    read -s password
    echo
    echo -n "もう一度入力してください : "
    read -s confirm
    if [[ ! $password = $confirm ]]; then
        echo
        echo "同じパスワードが入力されませんでした。"
        set_password
    elif [[ -z $password || -z $confirm ]]; then
        echo
        echo "パスワードを入力してください。"
        set_password
    fi
    unset confirm
    echo
}

function generate_argument () {
    if [[ ${plymouth} = true ]]; then
        argument="${argument} -b"
    fi
    if [[ -n ${comp_type} ]]; then
        argument="${argument} -c ${comp_type}"
    fi
    if [[ -n ${password} ]]; then
        argument="${argument} -p ${password}"
    fi
}

function ask () {
    enable_plymouth
    select_comp_type
    set_comp_option
    set_password
}

function lastcheck () {
    echo "以下の設定でビルドを開始します。"
    echo
    echo "Plymouth : ${plymouth}"
    echo "圧縮方式   : ${comp_type}"
    echo "Password : ${password}"
    echo
    echo -n "この設定で続行します。よろしいですか？ (y/N) : "
    local yn
    read yn
    case ${yn} in
        y | Y | yes | Yes | YES ) :         ;;
        n | N | no  | No  | NO  ) ask       ;;
        *                       ) lastcheck ;;
    esac
}


ask
lastcheck
generate_argument
echo ${argument}