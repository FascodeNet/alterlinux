#!/usr/bin/env bash
set -e

:<< TEXT
変数や関数の命名規則について

<< グローバル >>
グローバル変数: Var_Global_[変数名]
グローバル関数: Function_Global_[関数名]

[ Function_Global_Main_ask_questions内で使用する関数のみ ]
グローバル関数: Function_Global_Ask_[設定される変数名]

[ wizard.sh用の変数 ]
オプション用: Var_Global_Wizard_Option_
実行環境設定: Var_Global_Wizard_Env_

<< ローカル >>
ローカル変数: Var_Local_[変数名]
ローカル関数: Var_Local_[関数名]
TEXT


Var_Global_Wizard_Option_nobuild=false
script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"

Var_Global_Wizard_Env_machine_arch="$(uname -m)"
Var_Global_Wizard_Option_build_arch="${Var_Global_Wizard_Env_machine_arch}"

# Pacman configuration file used only when checking packages.
Var_Global_Wizard_Env_pacman_conf="${script_path}/system/pacman-${Var_Global_Wizard_Env_machine_arch}.conf"

# 言語（en or jp)
#Var_Global_Wizard_Option_language="jp"
Var_Global_Wizard_Option_language="en"
Var_Global_Wizard_Option_skip_language=false



# メッセージを表示する
# msg [日本語] [英語]
msg() {
    if [[ ${Var_Global_Wizard_Option_language} = "jp" ]]; then
        echo "${1}"
    else
        echo "${2}"
    fi
}
msg_error() {
    if [[ ${Var_Global_Wizard_Option_language} = "jp" ]]; then
        echo "${1}" >&2
    else
        echo "${1}" >&2
    fi
}
msg_n() {
    if [[ ${Var_Global_Wizard_Option_language} = "jp" ]]; then
        echo -n "${1}"
    else
        echo -n "${2}"
    fi
}


# Usage: getclm <number>
# 標準入力から値を受けとり、引数で指定された列を抽出します。
getclm() {
    echo "$(cat -)" | cut -d " " -f "${1}"
}

# 使い方
_help() {
    echo "usage ${0} [options]"
    echo
    echo " General options:"
    echo "    -a          Specify the architecture"
    echo "    -e          English"
    echo "    -j          Japanese"
    echo "    -n          Enable simulation mode"
    echo "    -x          Enable bash debug"
    echo "    -h          This help message"
}

while getopts 'a:xnjeh' arg; do
    case "${arg}" in
        n)
            Var_Global_Wizard_Option_nobuild=true
            msg \
                "シミュレーションモードを有効化しました" "Enabled simulation mode"
            ;;
        x)
            set -x
            msg "デバッグモードを有効化しました" "Debug mode enabled"
            ;;
        e)
            Var_Global_Wizard_Option_language="en"
            echo "English is set"
            Var_Global_Wizard_Option_skip_language=true
            ;;
        j)
            Var_Global_Wizard_Option_language="jp"
            echo "日本語が設定されました"
            Var_Global_Wizard_Option_skip_language=true
            ;;
        h)
            _help
            exit 0
            ;;
        a)
            Var_Global_Wizard_Option_build_arch="${OPTARG}"
            ;;
        *)
            _help
            exit 1
            ;;
    esac
done

Function_Global_Main_wizard_language () {
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
        read Var_Global_Wizard_Option_language

        case ${Var_Global_Wizard_Option_language} in
            1 ) Var_Global_Wizard_Option_language=en ;;
            2 ) Var_Global_Wizard_Option_language=jp ;;
            "英語" ) Var_Global_Wizard_Option_language=en ;;
            "日本語" ) Var_Global_Wizard_Option_language=jp ;;
            "English" ) Var_Global_Wizard_Option_language=en ;;
            "Japanese" ) Var_Global_Wizard_Option_language=jp ;;
            * ) Function_Global_Main_wizard_language ;;
        esac
    fi
}

Function_Global_Main_check_required_files () {
    local file _chkfile i error=false
    _chkfile() {
        if [[ ! -f "${1}" ]]; then
            msg_error "${1}が見つかりませんでした。" "${1} was not found."
            error=true
        fi
    }

    file=(
        "build.sh"
        "tools/keyring.sh"
        "system/pacman-i686.conf"
        "system/pacman-x86_64.conf"
        "default.conf"
    )

    for i in ${file[@]}; do
        _chkfile "${script_path}/${i}"
    done
    if [[ "${error}" = true ]]; then
        exit 1
    fi
}

Function_Global_Main_load_default () {
    source "${script_path}/default.conf"
}

Function_Global_Main_install_dependent_packages () {
    local checkpkg pkg installed_pkg installed_ver check_pkg

    msg "データベースの更新をしています..." "Updating package datebase..."
    sudo pacman -Sy --config "${Var_Global_Wizard_Env_pacman_conf}"
    installed_pkg=($(pacman -Q | getclm 1))
    installed_ver=($(pacman -Q | getclm 2))

    check_pkg() {
        local i
        for i in $(seq 0 $(( ${#installed_pkg[@]} - 1 ))); do
            if [[ ${installed_pkg[${i}]} = ${1} ]]; then
                if [[ ${installed_ver[${i}]} = $(pacman -Sp --print-format '%v' --config "${Var_Global_Wizard_Env_pacman_conf}" ${1}) ]]; then
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
    echo
    for pkg in ${dependence[@]}; do
        msg "依存パッケージ ${pkg} を確認しています..." "Checking dependency package ${pkg} ..."
        if [[ $(check_pkg ${pkg}) = false ]]; then
            install=(${install[@]} ${pkg})
        fi
    done
    if [[ -n "${install}" ]]; then
        sudo pacman -S --needed --config "${Var_Global_Wizard_Env_pacman_conf}" ${install[@]}
    fi
    echo
}

Function_Global_Main_guide_to_the_web () {
    if [[ "${Var_Global_Wizard_Option_language}"  = "jp" ]]; then
        msg "wizard.sh ではビルドオプションの生成以外にもパッケージのインストールやキーリングのインストールなど様々なことを行います。"
        msg "もし既に環境が構築されておりそれらの操作が必要ない場合は、以下のサイトによるジェネレータも使用することができます。"
        msg "http://hayao.fascode.net/alteriso-options-generator/"
        echo
    fi
}

Function_Global_Main_setup_keyring () {
    local yn
    msg_n "Alter Linuxの鍵を追加しますか？（y/N）: " "Are you sure you want to add the Alter Linux key? (y/N):"
    read yn
    if ${Var_Global_Wizard_Option_nobuild}; then
        msg \
            "${yn}が入力されました。シミュレーションモードが有効化されているためスキップします。" \
            "You have entered ${yn}. Simulation mode is enabled and will be skipped."
    else
        case ${yn} in
            y | Y | yes | Yes | YES ) sudo "${script_path}/keyring.sh" --alter-add   ;;
            n | N | no  | No  | NO  ) return 0                                       ;;
            *                       ) Function_Global_Main_setup_keyring                             ;;
        esac
    fi
}


Function_Global_Main_remove_dependent_packages () {
    if [[ -n "${install}" ]]; then
        sudo pacman -Rsn --config "${Var_Global_Wizard_Env_pacman_conf}" ${install[@]}
    fi
}


Function_Global_Ask_Var_Global_Wizard_Option_build_arch() {
    local yn
    local details
    local ask_arch
    msg_n "アーキテクチャを指定しますか？ （y/N） : " "Do you want to specify the architecture? (y/N)"
    read yn
    case ${yn} in
        y | Y | yes | Yes | YES ) details=true               ;;
        n | N | no  | No  | NO  ) details=false              ;;
        *                       ) Function_Global_Ask_comp_type; return 0 ;;
    esac

    ask_arch () {
        local ask
        msg \
            "アーキテクチャを選択して下さい " \
            "Please select an architecture."
        msg \
            "注意：このウィザードでは正式にサポートされているアーキテクチャのみ選択可能です。" \
            "Note: Only officially supported architectures can be selected in this wizard."
        echo
        echo "1: x86_64 (64bit)"
        echo "2: i686 (32bit)"
        echo -n ": "

        read ask

        case "${ask}" in
            1 | "x86_64" ) Var_Global_Wizard_Option_build_arch="x86_64" ;;
            2 | "i686"   ) Var_Global_Wizard_Option_build_arch="i686"   ;;
            *            ) ask_arch            ;;
        esac
    }

    if [[ ${details} = true ]]; then
        ask_arch
    else
        Var_Global_Wizard_Option_build_arch="${Var_Global_Wizard_Env_machine_arch}"
    fi

    return 0
}

Function_Global_Ask_plymouth () {
    local yn
    msg_n "Plymouthを有効化しますか？[no]（y/N） : " "Do you want to enable Plymouth? [no] (y/N) : "
    read yn
    case ${yn} in
        y | Y | yes | Yes | YES ) plymouth=true   ;;
        n | N | no  | No  | NO  ) plymouth=false  ;;
        *                       ) Function_Global_Ask_plymouth ;;
    esac
}


Function_Global_Ask_japanese () {
    local yn
    msg_n "日本語を有効化しますか？[no]（y/N） : " "Do you want to activate Japanese? [no] (y/N) : "
    read yn
    case ${yn} in
        y | Y | yes | Yes | YES ) japanese=true   ;;
        n | N | no  | No  | NO  ) japanese=false  ;;
        *                       ) Function_Global_Ask_japanese ;;
    esac
}


Function_Global_Ask_comp_type () {
    local yn
    local details
    local ask_comp_type
    msg_n "圧縮方式を設定しますか？[zstd]（y/N） : " "Do you want to set the compression method?[zstd](y/N)"
    read yn
    case ${yn} in
        y | Y | yes | Yes | YES ) details=true               ;;
        n | N | no  | No  | NO  ) details=false              ;;
        *                       ) Function_Global_Ask_comp_type; return 0 ;;
    esac

    ask_comp_type () {
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


Function_Global_Ask_comp_option () {
    local ask_comp_option
    ask_comp_option() {
        local gzip
        local lzo
        local lz4
        local xz
        local zstd
        comp_option=""

        gzip () {
            local comp_level
            comp_level () {
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
            window_size () {
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

        lz4 () {
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

        zstd () {
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

        lzo () {
            msg_error \
                "現在lzoの詳細設定ウィザードがサポートされていません。" \
                "The lzo Advanced Wizard is not currently supported."
        }

        xz () {
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
            *                       ) Function_Global_Ask_comp_option; return 0 ;;
        esac
        if [[ ${details} = true ]]; then
            ask_comp_option
            return 0
        else
            return 0
        fi
    fi
}


Function_Global_Ask_username () {
    local details
    local ask_comp_type
    msg_n \
        "デフォルトではないユーザー名を設定しますか？ （y/N） : " \
        "Would you like to set a non-default username? （y/N） : "
    read yn
    case ${yn} in
        y | Y | yes | Yes | YES ) details=true           ;;
        n | N | no  | No  | NO  ) details=false          ;;
        *                       ) Function_Global_Ask_username; return 0 ;;
    esac

    ask_username () {
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


Function_Global_Ask_password () {
    local details
    local ask_comp_type
    msg_n \
        "デフォルトではないパスワードを設定しますか？ （y/N） : " \
        "Do you want to set a non-default password? （y/N） : "
    read yn
    case ${yn} in
        y | Y | yes | Yes | YES ) details=true           ;;
        n | N | no  | No  | NO  ) details=false          ;;
        *                       ) Function_Global_Ask_password; return 0 ;;
    esac

    ask_password () {
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


Function_Global_Ask_kernel () {
    set +e
    local do_you_want_to_select_kernel

    do_you_want_to_select_kernel () {
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

    what_kernel () {
        msg \
            "使用するカーネルを以下の番号から選択してください" \
            "Please select the kernel to use from the following numbers"


        #カーネルの一覧を取得
        kernel_list=($(cat ${script_path}/system/kernel_list-${Var_Global_Wizard_Option_build_arch} | grep -h -v ^'#'))

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
Function_Global_Ask_channel () {

    local i count=1 _channel channel_list description

    # チャンネルの一覧を取得
    channel_list=($("${script_path}/tools/channel.sh" --nobuiltin show))

    msg "チャンネルを以下の番号から選択してください。" "Select a channel from the numbers below."

    # 選択肢を生成
    for _channel in ${channel_list[@]}; do
        if [[ -f "${script_path}/channels/${_channel}/description.txt" ]]; then
            description=$(cat "${script_path}/channels/${_channel}/description.txt")
        else
            if [[ "${Var_Global_Wizard_Option_language}"  = "jp" ]]; then
                description="このチャンネルにはdescription.txtがありません。"
            else
                description="This channel does not have a description.txt."
            fi
        fi
        echo -ne "$(printf %02d "${count}")    ${_channel}"
        for i in $( seq 1 $(( 19 - ${#_channel} )) ); do
            echo -ne " "
        done
        echo -ne "${description}\n"
        count="$(( count + 1 ))"
    done
    echo -n ":"
    read channel

    # 入力された値が数字かどうか判定する
    set +e
    expr "${channel}" + 1 >/dev/null 2>&1
    if [[ ${?} -lt 2 ]]; then
        set -e
        # 数字である
        channel=$(( channel - 1 ))
        if [[ -z "${channel_list[${channel}]}" ]]; then
            Function_Global_Ask_channel
            return 0
        else
            channel="${channel_list[${channel}]}"
        fi
    else
        set -e
        # 数字ではない
        if [[ ! $(printf '%s\n' "${channel_list[@]}" | grep -qx "${channel}"; echo -n ${?} ) -eq 0 ]]; then
            Function_Global_Ask_channel
            return 0
        fi
    fi

    echo "${channel}"

    return 0
}


# イメージファイルの所有者
Function_Global_Ask_owner () {
    local owner
    local user_check
    user_check () {
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
        Function_Global_Ask_owner
        return 0
    elif  [[ -z "${owner}" ]]; then
        echo "ユーザー名を入力して下さい。"
        Function_Global_Ask_owner
        return 0
    elif [[ "${owner}" = root ]]; then
        echo "所有者の変更を行いません。"
        return 0
    fi
}


# イメージファイルの作成先
Function_Global_Ask_out_dir () {
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
            Function_Global_Ask_out_dir
            return 0
        elif [[ "${out_dir}" = / ]] || [[ "${out_dir}" = /home ]]; then
            msg_error \
                "そのディレクトリは使用できません。" \
                "The directory is unavailable."
            Function_Global_Ask_out_dir
            return 0
        elif [[ -n "$(ls ${out_dir})" ]]; then
            msg_error \
                "ディレクトリは空ではありません。" \
                "The directory is not empty."
            Function_Global_Ask_out_dir
            return 0
        fi
    fi
}

Function_Global_Ask_tarball () {
    local yn
    msg_n "tarballをビルドしますか？[no]（y/N） : " "Build a tarball? [no] (y/N) : "
    read yn
    case ${yn} in
        y | Y | yes | Yes | YES ) tarball=true   ;;
        n | N | no  | No  | NO  ) tarball=false  ;;
        *                       ) Function_Global_Ask_tarball ;;
    esac
}


# 最終的なbuild.shのオプションを生成
Function_Global_Main_create_argument () {
    local _ADD_ARG
    _ADD_ARG () {
        argument="${argument} ${@}"
    }

    [[ "${japanese}" = true  ]] && _ADD_ARG "-l ja"
    [[ ${plymouth} = true    ]] && _ADD_ARG "-b"
    [[ -n ${comp_type}       ]] && _ADD_ARG "-c ${comp_type}"
    [[ -n ${kernel}          ]] && _ADD_ARG "-k ${kernel}"
    [[ -n "${username}"      ]] && _ADD_ARG "-u '${username}'"
    [[ -n "${password}"      ]] && _ADD_ARG "-p '${password}'"
    [[ -n "${out_dir}"       ]] && _ADD_ARG "-o '${out_dir}'"
    [[ "${tarball}" = true   ]] && _ADD_ARG "--tarball"
    argument="--noconfirm -a ${Var_Global_Wizard_Option_build_arch} ${argument} ${channel}"
}

# 上の質問の関数を実行
Function_Global_Main_ask_questions () {
    Function_Global_Ask_japanese
    Function_Global_Ask_Var_Global_Wizard_Option_build_arch
    Function_Global_Ask_plymouth
    Function_Global_Ask_kernel
    Function_Global_Ask_comp_type
    Function_Global_Ask_comp_option
    Function_Global_Ask_username
    Function_Global_Ask_password
    Function_Global_Ask_channel
    #Function_Global_Ask_owner
    Function_Global_Ask_tarball
    # Function_Global_Ask_out_dir
    Function_Global_Ask_Confirm
}

# ビルド設定の確認
Function_Global_Ask_Confirm () {
    msg "以下の設定でビルドを開始します。" "Start the build with the following settings."
    echo
    [[ -n "${japanese}"    ]] && echo "           Japanese : ${japanese}"
    [[ -n "${Var_Global_Wizard_Option_build_arch}"  ]] && echo "       Architecture : ${Var_Global_Wizard_Option_build_arch}"
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
        *                       ) Function_Global_Ask_Confirm ;;
    esac
}

Function_Global_Main_run_build.sh () {
    if [[ ${Var_Global_Wizard_Option_nobuild} = true ]]; then
        echo "${argument}"
    else
        # build.shの引数を表示（デバッグ用）
        # echo ${argument}
        sudo ./build.sh ${argument}
        sudo rm -rf work/
    fi
}


Function_Global_Main_run_clean.sh() {
    if [[ -d "${script_path}/work/" ]]; then
        sudo rm -rf "${script_path}/work/"
    fi
}


Function_Global_Main_set_iso_permission() {
    if [[ -n "${owner}" ]]; then
        chown -R "${owner}" "${script_path}/out/"
        chmod -R 750 "${script_path}/out/"
    fi
}

# 関数を実行
Function_Global_Main_wizard_language
Function_Global_Main_check_required_files
Function_Global_Main_load_default.conf
Function_Global_Main_install_dependent_packages
Function_Global_Main_guide_to_the_web
Function_Global_Main_setup_keyring
Function_Global_Main_ask_questions
Function_Global_Main_create_argument
Function_Global_Main_run_build.sh
Function_Global_Main_remove_dependent_packages
Function_Global_Main_run_clean.sh
Function_Global_Main_set_iso_permission
