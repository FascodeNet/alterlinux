#!/usr/bin/env bash

set -e

nobuild=false

script_path="$(readlink -f ${0%/*})"

build_arch=$(uname -m)

machine_arch=$(uname -m)

# Pacman configuration file used only when checking packages.
pacman_conf="${script_path}/system/pacman-${machine_arch}.conf"

# 言語（en or jp)
#lang="jp"
lang="en"
skip_set_lang=false


dependence=(
    "alterlinux-keyring"
#   "archiso"
    "arch-install-scripts"
    "curl"
    "dosfstools"
    "git"
    "libburn"
    "libisofs"
    "lz4"
    "lzo"
    "make"
    "squashfs-tools"
    "libisoburn"
 #  "lynx"
    "xz"
    "zlib"
    "zstd"
)


# メッセージを表示する
# msg [日本語] [英語]
function msg() {
    if [[ ${lang} = "jp" ]]; then
        echo "${1}"
    else
        echo "${2}"
    fi
}
function msg_error() {
    if [[ ${lang} = "jp" ]]; then
        echo "${1}" >&2
    else
        echo "${1}" >&2
    fi
}
function msg_n() {
    if [[ ${lang} = "jp" ]]; then
        echo -n "${1}"
    else
        echo -n "${2}"
    fi
}

while getopts 'a:xnje' arg; do
    case "${arg}" in
        n)
            nobuild=true
            msg \
                "シミュレーションモードを有効化しました" "Enabled simulation mode"
            ;;
        x)
            set -x 
            msg "デバッグモードを有効化しました" "Debug mode enabled"
            ;;
        e)
            lang="en"
            echo "English is set"
            skip_set_lang=true
            ;;
        j)
            lang="jp"
            echo "日本語が設定されました"
            skip_set_lang=true
            ;;
        a)
            build_arch="${OPTARG}"
            ;;
    esac
done

function set_language () {
    if [[ ${skip_set_lang} = false ]]; then
        echo "このウィザードでどちらの言語を使用しますか？"
        echo "この質問はウィザード内のみの設定であり、ビルドへの影響はありません。"
        echo
        echo "Which language would you like to use for this wizard?"
        echo "This question is a wizard-only setting and does not affect the build."
        echo
        echo "1: 英語 English"
        echo "2: 日本語 Japanese"
        echo
        echo -n ": "
        read lang

        case ${lang} in
            1 ) lang=en ;;
            2 ) lang=jp ;;
            "英語" ) lang=en ;;
            "日本語" ) lang=jp ;;
            "English" ) lang=en ;;
            "Japanese" ) lang=jp ;;
            * ) set_language ;;
        esac
    fi
}

function check_files () {
    local file
    local _chkfile
    local i
    local error

    error=false
    _chkfile() {
        if [[ ! -f "${1}" ]]; then
            msg_error "${1}が見つかりませんでした。" "${1} was not found."
            error=true
        fi
    }

    file=(
        "build.sh"
        "keyring.sh"
        "system/pacman-i686.conf"
        "system/pacman-x86_64.conf"
    )

    for i in ${file[@]}; do
        _chkfile "${script_path}/${i}"
    done
    if [[ "${error}" = true ]]; then
        exit 1
    fi
}


function install_dependencies () {
    local checkpkg
    local pkg
    local installed_pkg
    local installed_ver
    local check_pkg

    msg "データベースの更新をしています..." "Updating package datebase..."
    sudo pacman -Sy --config "${pacman_conf}"
    installed_pkg=($(pacman -Q | awk '{print $1}'))
    installed_ver=($(pacman -Q | awk '{print $2}'))

    check_pkg() {
        local i
        for i in $(seq 0 $(( ${#installed_pkg[@]} - 1 ))); do
            if [[ ${installed_pkg[${i}]} = ${1} ]]; then
                if [[ ${installed_ver[${i}]} = $(pacman -Sp --print-format '%v' --config ${pacman_conf} ${1}) ]]; then
                    echo -n "true"
                    return 0
                else
                    echo -n "false"
                    return 0
                fi
            fi
        done
        echo -n "false"
        return 0
    }

    for pkg in ${dependence[@]}; do
        msg "依存パッケージ ${pkg} を確認しています..." "Checking dependency package ${pkg} ..."
        if [[ $(check_pkg ${pkg}) = false ]]; then
            install=(${install[@]} ${pkg})
        fi
    done
    if [[ -n "${install[@]}" ]]; then
        sudo pacman -Sy
        sudo pacman -S --needed --config ${pacman_conf} ${install[@]}
    fi
    echo
}


function run_add_key_script () {
    local yn
    msg_n "AlterLinuxの鍵を追加しますか？（y/N）: " "Are you sure you want to add the AlterLinux key? (y/N):"
    read yn
    if ${nobuild}; then
        msg \
            "${yn}が入力されました。シミュレーションモードが有効化されているためスキップします。" \
            "You have entered ${yn}. Simulation mode is enabled and will be skipped."
    else
        case ${yn} in
            y | Y | yes | Yes | YES ) sudo "${script_path}/keyring.sh" --alter-add   ;;
            n | N | no  | No  | NO  ) return 0                                       ;;
            *                       ) run_add_key_script                             ;;
        esac
    fi
}


function remove_dependencies () {
    if [[ -n "${install[@]}" ]]; then
        sudo pacman -Rsn --config ${pacman_conf} ${install[@]}
    fi
}


function enable_plymouth () {
    local yn
    msg_n "Plymouthを有効化しますか？[no]（y/N） : " "Do you want to enable Plymouth? [no] (y/N) : "
    read yn
    case ${yn} in
        y | Y | yes | Yes | YES ) plymouth=true   ;;
        n | N | no  | No  | NO  ) plymouth=false  ;;
        *                       ) enable_plymouth ;;
    esac
}


function enable_japanese () {
    local yn
    msg_n "日本語を有効化しますか？[no]（y/N） : " "Do you want to activate Japanese? [no] (y/N) : "
    read yn
    case ${yn} in
        y | Y | yes | Yes | YES ) japanese=true   ;;
        n | N | no  | No  | NO  ) japanese=false  ;;
        *                       ) enable_japanese ;;
    esac
}


function select_comp_type () {
    local yn
    local details
    local ask_comp_type
    msg_n "圧縮方式を設定しますか？[zstd]（y/N） : " "Do you want to set the compression method?[zstd](y/N)"
    read yn
    case ${yn} in
        y | Y | yes | Yes | YES ) details=true               ;;
        n | N | no  | No  | NO  ) details=false              ;;
        *                       ) select_comp_type; return 0 ;;
    esac

    function ask_comp_type () {
        msg \
            "圧縮方式を以下の番号から選択してください " \
            "Please select the compression method from the following numbers"
        echo
        echo "1: gzip"
        echo "2: lzma"
        echo "3: lzo"
        echo "4: lz4"
        echo "5: xz"
        echo "6: zstd (default)"
        echo -n ": "

        read yn

        case ${yn} in
            1    ) comp_type="gzip" ;;
            2    ) comp_type="lzma" ;;
            3    ) comp_type="lzo"  ;;
            4    ) comp_type="lz4"  ;;
            5    ) comp_type="xz"   ;;
            6    ) comp_type="zstd" ;;
            gzip ) comp_type="gzip" ;;
            lzma ) comp_type="lzma" ;;
            lzo  ) comp_type="lzo"  ;;
            lz4  ) comp_type="lz4"  ;;
            xz   ) comp_type="xz"   ;;
            zstd ) comp_type="zstd" ;;
            *    ) ask_comp_type    ;;
        esac
    }

    if [[ ${details} = true ]]; then
        ask_comp_type
    else
        comp_type="zstd"
    fi

    return 0
}


function set_comp_option () {
    local ask_comp_option
    ask_comp_option() {
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
                msg_n "gzipの圧縮レベルを入力してください。 (1~22) : " "Enter the gzip compression level.  (1~22) : "
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
                msg_n \
                    "gzipのウィンドウサイズを入力してください。 (1~15) : " \
                    "Please enter the gzip window size. (1~15) : "

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
            msg_n \
                "高圧縮モードを有効化しますか？ （y/N） : " \
                "Do you want to enable high compression mode? （y/N） : "
            read yn
            case ${yn} in
                y | Y | yes | Yes | YES ) comp_option="-Xhc" ;;
                n | N | no  | No  | NO  ) :                  ;;
                *                       ) lz4                ;;
            esac
        }

        function zstd () {
            local level
            msg_n \
                "zstdの圧縮レベルを入力してください。 (1~22) : " \
                "Enter the zstd compression level. (1~22) : "
            read level
            if [[ ${level} -lt 23 && ${level} -ge 4 ]]; then
                comp_option="-Xcompression-level ${level}"
            else
                zstd
            fi
        }

        function lzo () {
            msg_error \
                "現在lzoの詳細設定ウィザードがサポートされていません。" \
                "The lzo Advanced Wizard is not currently supported."
        }

        function xz () {
            msg_error \
            "現在xzの詳細設定のウィザードがサポートされていません。" \
            "The xz Advanced Wizard is not currently supported."
        }

        case ${comp_type} in
            gzip ) gzip ;;
            zstd ) zstd ;;
            lz4  ) lz4  ;;
            lzo  ) lzo  ;;
            xz   ) xz   ;;
            *    ) :    ;;
        esac
    }

    # lzmaには詳細なオプションはありません。
    if [[ ! ${comp_type} = "lzma" ]]; then
        local yn
        local details
        msg_n \
            "圧縮の詳細を設定しますか？ （y/N） : " \
            "Do you want to set the compression details? （y/N） : "
        read yn
        case ${yn} in
            y | Y | yes | Yes | YES ) details=true              ;;
            n | N | no  | No  | NO  ) details=false             ;;
            *                       ) set_comp_option; return 0 ;;
        esac
        if [[ ${details} = true ]]; then
            ask_comp_option
            return 0
        else
            return 0
        fi
    fi
}


function set_username () {
    local details
    local ask_comp_type
    msg_n \
        "デフォルトではないユーザー名を設定しますか？ （y/N） : " \
        "Would you like to set a non-default username? （y/N） : "
    read yn
    case ${yn} in
        y | Y | yes | Yes | YES ) details=true           ;;
        n | N | no  | No  | NO  ) details=false          ;;
        *                       ) set_username; return 0 ;;
    esac

    function ask_username () {
        msg_n "ユーザー名を入力してください : " "Please enter your username : "
        read username
        if [[ -z ${username} ]]; then
            ask_username
        fi
    }

    if [[ ${details} = true ]]; then
        ask_username
    fi

    return 0
}


function set_password () {
    local details
    local ask_comp_type
    msg_n \
        "デフォルトではないパスワードを設定しますか？ （y/N） : " \
        "Do you want to set a non-default password? （y/N） : "
    read yn
    case ${yn} in
        y | Y | yes | Yes | YES ) details=true           ;;
        n | N | no  | No  | NO  ) details=false          ;;
        *                       ) set_password; return 0 ;;
    esac

    function ask_password () {
        msg_n "パスワードを入力してください。" "Please enter your password."
        read -s password
        echo
        msg_n "Type it again : "
        read -s confirm
        if [[ ! $password = $confirm ]]; then
            echo
            msg_error "同じパスワードが入力されませんでした。" "You did not enter the same password."
            ask_password
        elif [[ -z $password || -z $confirm ]]; then
            echo
            msg_error "パスワードを入力してください。" "Please enter your password."
            ask_password
        fi
        echo
        unset confirm
    }

    if [[ ${details} = true ]]; then
        ask_password
    fi

    return 0
}


function select_kernel () {
    set +e
    local do_you_want_to_select_kernel

    function do_you_want_to_select_kernel () {
        set +e
        local yn
        msg_n \
            "デフォルト（zen）以外のカーネルを使用しますか？ （y/N） : " \
            "Do you want to use a kernel other than the default (zen)? (y/N) : "
        read yn
        case ${yn} in
            y | Y | yes | Yes | YES ) return 0                               ;;
            n | N | no  | No  | NO  ) return 1                               ;;
            *                       ) do_you_want_to_select_kernel; return 0 ;;
        esac

    }

    local what_kernel

    function what_kernel () {
        msg \
            "使用するカーネルを以下の番号から選択してください" \
            "Please select the kernel to use from the following numbers"


        #カーネルの一覧を取得
        kernel_list=($(cat ${script_path}/system/kernel_list-${build_arch} | grep -h -v ^'#'))

        #選択肢の生成
        local count=1
        local i
        echo
        for i in ${kernel_list[@]}; do
            echo "${count}: linux-${i}"
            count=$(( count + 1 ))
        done

        # 質問する
        echo -n ": "
        local answer
        read answer

        # 回答を解析する
        # 数字かどうか判定する
        set +e
        expr "${answer}" + 1 >/dev/null 2>&1
        if [[ ${?} -lt 2 ]]; then
            set -e
            # 数字である
            answer=$(( answer - 1 ))
            if [[ -z "${kernel_list[${answer}]}" ]]; then
                what_kernel
                return 0
            else
                kernel="${kernel_list[${answer}]}"
            fi
        else
            set -e
            # 数字ではない
            # 配列に含まれるかどうか判定
            if [[ ! $(printf '%s\n' "${kernel_list[@]}" | grep -qx "${answer#linux-}"; echo -n ${?} ) -eq 0 ]]; then
                ask_channel
                return 0
            else
                kernel="${answer#linux-}"
            fi
        fi
    }

    do_you_want_to_select_kernel
    exit_code=$?
    if [[ ${exit_code} = 0 ]]; then
        what_kernel
    fi
    set -e
}


# チャンネルの指定
function select_channel () {
    local ask_channel

    msg_n \
        "デフォルト（xfce）以外のチャンネルを使用しますか？ （y/N） : " \
        "Do you want to use a channel other than the default (xfce)? (y/N) : "

    read yn
    case ${yn} in
        y | Y | yes | Yes | YES ) details=true             ;;
        n | N | no  | No  | NO  ) details=false            ;;
        *                       ) select_channel; return 0 ;;
    esac

    function ask_channel () {
        local i
        local count
        local _channel
        local channel_list
        local description

        # チャンネルの一覧を生成
        for i in $(ls -l "${script_path}"/channels/ | awk '$1 ~ /d/ {print $9 }'); do
            if [[ -n $(ls "${script_path}"/channels/${i}) ]] && [[ ! ${i} = "share" ]]; then
                if [[ -n $(cat ${script_path}/channels/${i}/architecture | grep -h -v ^'#' | grep -x "${build_arch}") ]]; then
                    channel_list=(${channel_list[@]} ${i})
                fi
            fi
        done
        msg "チャンネルを以下の番号から選択してください。" "Select a channel from the numbers below."
        count=1
        for _channel in ${channel_list[@]}; do
            if [[ -f "${script_path}/channels/${_channel}/description.txt" ]]; then
                description=$(cat "${script_path}/channels/${_channel}/description.txt")
            else
                if [[ "${lang}"  = "jp" ]]; then
                    description="このチャンネルにはdescription.txtがありません。"
                else
                    description="This channel does not have a description.txt."
                fi
            fi
            if [[ $(echo "${_channel}" | sed 's/^.*\.\([^\.]*\)$/\1/') = "add" ]]; then
                echo -ne "${count}    $(echo ${_channel} | sed 's/\.[^\.]*$//')"
                for i in $( seq 1 $(( 23 - ${#_channel} )) ); do
                    echo -ne " "
                done
            else
                echo -ne "${count}    ${_channel}"
                for i in $( seq 1 $(( 19 - ${#_channel} )) ); do
                    echo -ne " "
                done
            fi
            echo -ne "${description}\n"
            count=$(( count + 1 ))
        done
        echo -n ":"
        read channel

        # 数字かどうか判定する
        set +e
        expr "${channel}" + 1 >/dev/null 2>&1
        if [[ ${?} -lt 2 ]]; then
            set -e
            # 数字である
            channel=$(( channel - 1 ))
            if [[ -z "${channel_list[${channel}]}" ]]; then
                ask_channel
                return 0
            else
                channel="${channel_list[${channel}]}"
            fi
        else
            set -e
            # 数字ではない
            if [[ ! $(printf '%s\n' "${channel_list[@]}" | grep -qx "${channel}.add"; echo -n ${?} ) -eq 0 ]]; then
                if [[ ! $(printf '%s\n' "${channel_list[@]}" | grep -qx "${channel}"; echo -n ${?} ) -eq 0 ]]; then
                    ask_channel
                    return 0
                fi
            fi
        fi
    }

    if [[ ${details} = true ]]; then
        ask_channel
    fi
    # echo ${channel}
    return 0
}


# イメージファイルの所有者
function set_iso_owner () {
    local owner
    local user_check
    function user_check () {
    if [[ $(getent passwd $1 > /dev/null ; printf $?) = 0 ]]; then
        if [[ -z $1 ]]; then
            echo -n "false"
        fi
        echo -n "true"
    else
        echo -n "false"
    fi
    }

    msg_n "イメージファイルの所有者を入力してください。: " "Enter the owner of the image file.: "
    read owner
    if [[ $(user_check ${owner}) = false ]]; then
        echo "ユーザーが存在しません。"
        set_iso_owner
        return 0
    elif  [[ -z "${owner}" ]]; then
        echo "ユーザー名を入力して下さい。"
        set_iso_owner
        return 0
    elif [[ "${owner}" = root ]]; then
        echo "所有者の変更を行いません。"
        return 0
    fi
}


# イメージファイルの作成先
function set_out_dir () {
    msg "イメージファイルの作成先を入力して下さい。" "Enter the destination to create the image file."
    msg "デフォルトは ${script_path}/out です。" "The default is ${script_path}/out."
    echo -n ": "
    read out_dir
    if [[ -z "${out_dir}" ]]; then
        out_dir=out
    else
        if [[ ! -d "${out_dir}" ]]; then
            msg_error \
                "存在しているディレクトリを指定して下さい。" \
                "Please specify the existing directory."
            set_out_dir
            return 0
        elif [[ "${out_dir}" = / ]] || [[ "${out_dir}" = /home ]]; then
            msg_error \
                "そのディレクトリは使用できません。" \
                "The directory is unavailable."
            set_out_dir
            return 0
        elif [[ -n "$(ls ${out_dir})" ]]; then
            msg_error \
                "ディレクトリは空ではありません。" \
                "The directory is not empty."
            set_out_dir
            return 0
        fi
    fi
}


# 最終的なbuild.shのオプションを生成
function generate_argument () {
    if [[ ${japanese} = true ]]; then
        argument="${argument} -j"
    fi
    if [[ ${plymouth} = true ]]; then
        argument="${argument} -b"
    fi
    if [[ -n ${comp_type} ]]; then
        argument="${argument} -c ${comp_type}"
    fi
    if [[ -n ${kernel} ]]; then
        argument="${argument} -k ${kernel}"
    fi
    if [[ -n "${username}" ]]; then
        argument="${argument} -u '${username}'"
    fi
    if [[ -n ${password} ]]; then
        argument="${argument} -p '${password}'"
    fi
    if [[ -n ${out_dir} ]]; then
        argument="${argument} -o '${out_dir}'"
    fi
    argument="-a ${build_arch} ${argument} ${channel}"
}

#　上の質問の関数を実行
function ask () {
    enable_japanese
    enable_plymouth
    select_kernel
    select_comp_type
    set_comp_option
    set_username
    set_password
    select_channel
    set_iso_owner
    # set_out_dir
    lastcheck
}

# ビルド設定の確認
function lastcheck () {
    msg "以下の設定でビルドを開始します。" "Start the build with the following settings."
    echo
    [[ -n "${japanese}"    ]] && echo "           Japanese : ${japanese}"
    [[ -n "${plymouth}"    ]] && echo "           Plymouth : ${plymouth}"
    [[ -n "${kernel}"      ]] && echo "             kernel : ${kernel}"
    [[ -n "${comp_type}"   ]] && echo " Compression method : ${comp_type}"
    [[ -n "${comp_option}" ]] && echo "Compression options : ${comp_option}"
    [[ -n "${username}"    ]] && echo "           Username : ${username}"
    [[ -n "${password}"    ]] && echo "           Password : ${password}"
    [[ -n "${channel}"     ]] && echo "            Channel : ${channel}"
    echo
    msg_n \
        "この設定で続行します。よろしいですか？ (y/N) : " \
        "Continue with this setting. Is it OK? (y/N) : "
    local yn
    read yn
    case ${yn} in
        y | Y | yes | Yes | YES ) :         ;;
        n | N | no  | No  | NO  ) ask       ;;
        *                       ) lastcheck ;;
    esac
}

function start_build () {
    if [[ ${nobuild} = true ]]; then
        echo "${argument}"
    else
        # build.shの引数を表示（デバッグ用）
        # echo ${argument}
        sudo ./build.sh ${argument}
        sudo rm -rf work/
    fi
}


remove_work_dir() {
    if [[ -d "${script_path}/work/" ]]; then
        sudo rm -rf "${script_path}/work/"
    fi
}


change_iso_permission() {
    if [[ -n "${owner}" ]]; then
        chown -R "${owner}" "${script_path}/out/"
        chmod -R 750 "${script_path}/out/"
    fi
}

# 関数を実行
set_language
check_files
install_dependencies
run_add_key_script
ask
generate_argument
start_build
remove_dependencies
remove_work_dir
change_iso_permission
