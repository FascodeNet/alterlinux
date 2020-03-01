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

    # lzmaには詳細なオプションはありません。
    if [[ ! ${comp_type} = "lzma" ]]; then
        local yn
        local details
        echo -n "圧縮の詳細を設定しますか？ （y/N） : "
        read yn
        case ${yn} in
            y | Y | yes | Yes | YES ) details=true    ;;
            n | N | no  | No  | NO  ) details=false   ;;
            *                       ) set_comp_option ; return 0;;
        esac
        if ${details}; then
            :
        else
            return 0
        fi

        local gzip
        local lzo
        local lz4
        local xz
        local zstd
        comp_option=""

        function gzip () {
            local comp_level
            function comp_level () {
                local level
                echo -n "gzipの圧縮レベルを入力してください。 (1~22) : "
                read level
                if [[ ${level} -lt 23 && ${level} -ge 4 ]]; then
                    comp_option="-Xcompression-level ${level}"
                else
                    comp_level
                fi
            }
            local window_size
            function window_size () {
                local window
                echo -n "gzipのウィンドウサイズを入力してください。 (1~15) : "
                read window
                if [[ ${window} -lt 16 && ${window} -ge 4 ]]; then
                    comp_option="${comp_option} -Xwindow-size ${window}"
                else
                    window_size
                fi
            }

        }

        function lz4 () {
            local yn
            echo -n "高圧縮モードを有効化しますか？ （y/N） : "
            read yn
            case ${yn} in
                y | Y | yes | Yes | YES ) comp_option="-Xhc" ;;
                n | N | no  | No  | NO  ) :                  ;;
                *                       ) lz4                ;;
            esac
        }

        function zstd () {
            local level
            echo -n "zstdの圧縮レベルを入力してください。 (1~22) : "
            read level
            if [[ ${level} -lt 23 && ${level} -ge 4 ]]; then
                comp_option="-Xcompression-level ${level}"
            else
                zstd
            fi
        }

        function lzo () {
            echo "現在lzoは詳細プションのウィザードがサポートされていません。" >&2
        }

        function xz () {
            echo "現在xzは詳細プションのウィザードがサポートされていません。" >&2
        }

        case ${comp_type} in
            gzip ) gzip ;;
            zstd ) zstd ;;
            lz4  ) lz4  ;;
            lzo  ) lzo  ;;
            xz   ) xz   ;;
            *    ) :    ;;
        esac
    fi
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
}

function select_kernel () {
    set +e
    local do_you_want_to_select_kernel

    function do_you_want_to_select_kernel () {
        set +e
        local yn
        echo -n "通常以外のLinuxカーネルを使用しますか？ （y/N） : "
        read yn
        case ${yn} in
            y | Y | yes | Yes | YES ) return 0    ;;
            n | N | no  | No  | NO  ) return 1    ;;
            *                       ) do_you_want_to_select_kernel ; return;;
        esac

    }

    local what_kernel

    function what_kernel () {
        echo "使用するカーネルを以下の番号から選択してください "
        echo
        echo "1: linux-lts"
        echo "2: linux-zen"
        echo "3: linux-ck"
        echo "4: linux-rt"
        echo "5: linux-lqx"
        echo -n ": "

        read yn

        case ${yn} in
            1) kernel="lts" ;;
            2) kernel="zen" ;;
            3) kernel="ck"  ;;
            4) kernel="rt"  ;;
            5) kernel="lqx" ;;
            lts) kernel="lts" ;;
            zen) kernel="zen" ;;
            ck) kernel="ck"  ;;
            rt) kernel="rt"  ;;
            lqx) kernel="lqx" ;;
            *) what_kernel ;;
        esac
    }

    do_you_want_to_select_kernel
    exit_code=$?
    if [[ ${exit_code} = 0 ]]; then
        what_kernel
    fi
    set -e
}


# 最終的なbuild.shのオプションを生成
function generate_argument () {
    if [[ ${plymouth} = true ]]; then
        argument="${argument} -b"
    fi
    if [[ -n ${comp_type} ]]; then
        argument="${argument} -c ${comp_type}"
    fi
    if [[ -n ${kernel} ]]; then
        argument="${argument} -k ${kernel}"
    fi
    if [[ -n ${password} ]]; then
        argument="${argument} -p ${password}"
    fi
}

#　上の質問の関数を実行
function ask () {
    enable_plymouth
    select_kernel
    select_comp_type
    set_comp_option
    set_password
    lastcheck
}

# 将来的なビルド用の確認（このスクリプトは将来的には自動でcloneしビルドすることを目指しています。）
function lastcheck () {
    echo "以下の設定でビルドを開始します。"
    echo
    echo "           Plymouth : ${plymouth}"
    echo "             kernel : ${kernel}"
    echo " Compression method : ${comp_type}"
    echo "Compression options : ${comp_option}"
    echo "          Password  : ${password}"
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

function start_build () {
    # build.shの引数を表示（デバッグ用）
    # echo ${argument}
    sudo ./build.sh ${argument}
    make cleanup
}

# 関数を実行
ask
generate_argument
start_build