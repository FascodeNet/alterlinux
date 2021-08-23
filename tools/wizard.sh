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
Var_Global_Wizard_Env_script_path="${script_path}"

Var_Global_Wizard_Env_machine_arch="$(uname -m)"
Var_Global_Wizard_Option_build_arch="${Var_Global_Wizard_Env_machine_arch}"

# Pacman configuration file used only when checking packages.
Var_Global_Wizard_Env_pacman_conf="${Var_Global_Wizard_Env_script_path}/system/pacman-${Var_Global_Wizard_Env_machine_arch}.conf"

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
getclm() { cut -d " " -f "${1}"; }

# 使い方
Function_Global_help() {
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
            Function_Global_help
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
    if [[ "${Var_Global_Wizard_Option_skip_language}" = false ]]; then
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
        read -r Var_Global_Wizard_Option_language

        case "${Var_Global_Wizard_Option_language}" in
            "1" | "英語"   | "English"  | "en") Var_Global_Wizard_Option_language=en ;;
            "2" | "日本語" | "Japanese" | "ja") Var_Global_Wizard_Option_language=jp ;;
            *                                ) Function_Global_Main_wizard_language ;;
        esac
    fi
}

Function_Global_Main_check_required_files () {
    local Var_Local_file_list Var_Local_file Var_Local_error=false
    Var_Local_file_list=(
        "build.sh"
        "tools/keyring.sh"
        "tools/clean.sh"
        "tools/channel.sh"
        "tools/module.sh"
        "tools/locale.sh"
        "tools/kernel.sh"
        "tools/pkglist.sh"
        "tools/alteriso-info.sh"
        "tools/package.py"
        "tools/msg.sh"
        "system/kernel-i686"
        "system/kernel-x86_64"
        "system/locale-i686"
        "system/locale-x86_64"
        "system/pacman-i686.conf"
        "system/pacman-x86_64.conf"
        "default.conf"
    )

    for Var_Local_file in "${Var_Local_file_list[@]}"; do
        if [[ ! -f "${Var_Global_Wizard_Env_script_path}/${Var_Local_file}" ]]; then
            msg_error "${Var_Local_file}が見つかりませんでした。" "${Var_Local_file} was not found."
            Var_Local_error=true
        fi
    done
    if [[ "${Var_Local_error}" = true ]]; then
        exit 1
    fi
}

Function_Global_Main_load_default_config () {
    source "${Var_Global_Wizard_Env_script_path}/default.conf"
}

Function_Global_Main_check_yay(){
    if ! pacman -Qq yay > /dev/null 2>&1; then
        msg_error "yayが見つかりませんでした" "yay was not found."
        exit 1
    fi
}

Function_Global_Main_install_dependent_packages () {
    #local pkg installed_pkg installed_ver check_pkg
    local Function_Local_checkpkg Var_Local_package

    msg "データベースの更新をしています..." "Updating package datebase..."
    sudo pacman -Sy --config "${Var_Global_Wizard_Env_pacman_conf}"

    Function_Local_checkpkg () {
        local Var_Local_package Var_Local_installed_package Var_Local_installed_version
        readarray -t Var_Local_installed_package < <(pacman -Q | getclm 1)
        readarray -t Var_Local_installed_version < <(pacman -Q | getclm 2)
        for Var_Local_package in $(seq 0 $(( "${#Var_Local_installed_package[@]}" - 1 ))); do
            if [[ "${Var_Local_installed_package[${Var_Local_package}]}" = "${1}" ]]; then
                [[ "${Var_Local_installed_version[${Var_Local_package}]}" = "$(pacman -Sp --print-format '%v' --config "${Var_Global_Wizard_Env_pacman_conf}" "${1}")" ]] && return 0 || return 1
            fi
        done
        return 1
    }
    echo
    for Var_Local_package in "${dependence[@]}"; do
        msg "依存パッケージ ${Var_Local_package} を確認しています..." "Checking dependency package ${Var_Local_package} ..."
        if Function_Local_checkpkg "${Var_Local_package}"; then
            Var_Global_missing_packages+=("${Var_Local_package}")
        fi
    done
    if [[ -n "${Var_Global_missing_packages[*]}" ]]; then
        yay -S --needed --config "${Var_Global_Wizard_Env_pacman_conf}" "${Var_Global_missing_packages[@]}"
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

Function_Global_Main_run_keyring.sh () {
    local Var_Local_input_yes_or_no
    msg_n "Alter Linuxの鍵を追加しますか？（y/N）: " "Are you sure you want to add the Alter Linux key? (y/N):"
    read -r Var_Local_input_yes_or_no
    if ${Var_Global_Wizard_Option_nobuild}; then
        msg \
            "${Var_Local_input_yes_or_no}が入力されました。シミュレーションモードが有効化されているためスキップします。" \
            "You have entered ${Var_Local_input_yes_or_no}. Simulation mode is enabled and will be skipped."
    else
        case "${Var_Local_input_yes_or_no}" in
            "y" | "Y" | "yes" | "Yes" | "YES" ) sudo "${Var_Global_Wizard_Env_script_path}/keyring.sh" --alter-add   ;;
            "n" | "N" | "no"  | "No"  | "NO"  ) return 0                                       ;;
            *                                 ) Function_Global_Main_run_keyring.sh            ;;
        esac
    fi
}


Function_Global_Main_remove_dependent_packages () {
    if [[ -n "${Var_Global_missing_packages[*]}" ]]; then
        sudo pacman -Rsn --config "${Var_Global_Wizard_Env_pacman_conf}" "${Var_Global_missing_packages[@]}"
    fi
}


Function_Global_Ask_build_arch() {
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

    read -r Var_Global_Wizard_Option_build_arch

    case "${Var_Global_Wizard_Option_build_arch}" in
        1 | "x86_64" ) Var_Global_Wizard_Option_build_arch="x86_64" ;;
        2 | "i686"   ) Var_Global_Wizard_Option_build_arch="i686"   ;;
        *            ) Function_Global_Ask_build_arch               ;;
    esac
    return 0
}

Function_Global_Ask_plymouth () {
    local Var_Local_input_yes_or_no
    msg_n "Plymouthを有効化しますか？[no]（y/N） : " "Do you want to enable Plymouth? [no] (y/N) : "
    read -r Var_Local_input_yes_or_no
    case "${Var_Local_input_yes_or_no}" in
        "y" | "Y" | "yes" | "Yes" | "YES" ) Var_Global_Build_plymouth=true   ;;
        "n" | "N" | "no"  | "No"  | "NO"  ) Var_Global_Build_plymouth=false  ;;
        *                                 ) Function_Global_Ask_plymouth ;;
    esac
}

# この関数はAlterISO2以前を想定したものです。現在はコメントアウトされて実行されません。
Function_Global_Ask_japanese () {
    local Var_Local_input_yes_or_no
    msg_n "日本語を有効化しますか？[no]（y/N） : " "Do you want to activate Japanese? [no] (y/N) : "
    read -r Var_Local_input_yes_or_no
    case "${Var_Local_input_yes_or_no}" in
        "y" | "Y" | "yes" | "Yes" | "YES" ) Var_Global_Build_japanese=true   ;;
        "n" | "N" | "no"  | "No"  | "NO"  ) Var_Global_Build_japanese=false  ;;
        *                                 ) Function_Global_Ask_japanese ;;
    esac
}

# Function_Global_Ask_japaneseの代わりにFunction_Global_Ask_localeを使用して下さい。
Function_Global_Ask_locale() {
    msg \
        "ビルドする言語を以下の番号から選択して下さい " \
        "Please select the language to build from the following numbers"

    local Var_Local_locale_list Var_Local_locale Var_Local_count=1 Var_Local_input_locale
    #Var_Local_locale_list=($("${Var_Global_Wizard_Env_script_path}/tools/locale.sh" -a "${Var_Global_Wizard_Option_build_arch}" show))
    readarray -t Var_Local_locale_list < <("${Var_Global_Wizard_Env_script_path}/tools/locale.sh" -a "${Var_Global_Wizard_Option_build_arch}" show)
    for Var_Local_locale in "${Var_Local_locale_list[@]}"; do
        (
            local locale_name locale_gen_name locale_version locale_time locale_fullname
            eval "$("${Var_Global_Wizard_Env_script_path}/tools/locale.sh" -a "${Var_Global_Wizard_Option_build_arch}" get "${Var_Local_locale}" )"
            echo -n "$(printf %02d "${Var_Local_count}")    ${locale_name}"
            for Var_Local_int in $( seq 1 $(( 10 - ${#kernel} )) ); do echo -ne " "; done
            echo -ne "(${locale_fullname})\n"
        )
        Var_Local_count=$(( Var_Local_count + 1 ))
    done
    echo -n ": "
    read -r Var_Local_input_locale

    set +e
    expr "${Var_Local_input_locale}" + 1 >/dev/null 2>&1
    if [[ "${?}" -lt 2 ]]; then
        set -e
        # 数字である
        Var_Local_input_locale=$(( Var_Local_input_locale - 1 ))
        if [[ -z "${Var_Local_locale_list[${Var_Local_input_locale}]}" ]]; then
            Function_Global_Ask_locale
            return 0
        else
            Var_Global_Build_locale="${Var_Local_locale_list[${Var_Local_input_locale}]}"
            
        fi
    else
        set -e
        # 数字ではない
        # 配列に含まれるかどうか判定
        if [[ ! $(printf '%s\n' "${Var_Local_locale_list[@]}" | grep -qx "${Var_Local_input_locale}"; echo -n ${?} ) -eq 0 ]]; then
            Function_Global_Ask_locale
            return 0
        else
            Var_Global_Build_locale="${Var_Local_input_locale}"
        fi
    fi
}


Function_Global_Ask_comp_type () {
    local Var_Local_input_comp_type
    msg \
        "圧縮方式を以下の番号から選択してください " \
        "Please select the compression method from the following numbers"
    echo
    echo "1: gzip (default)"
    echo "2: lzma"
    echo "3: lzo"
    echo "4: lz4"
    echo "5: xz"
    echo "6: zstd"
    echo -n ": "
    read -r Var_Local_input_comp_type
    case "${Var_Local_input_comp_type}" in
        "1" | "gzip" ) Var_Global_Build_comp_type="gzip" ;;
        "2" | "lzma" ) Var_Global_Build_comp_type="lzma" ;;
        "3" | "lzo"  ) Var_Global_Build_comp_type="lzo"  ;;
        "4" | "lz4"  ) Var_Global_Build_comp_type="lz4"  ;;
        "5" | "xz"   ) Var_Global_Build_comp_type="xz"   ;;
        "6" | "zstd" ) Var_Global_Build_comp_type="zstd" ;;
        *            ) Function_Global_Ask_comp_type     ;;
    esac
    return 0
}


Function_Global_Ask_comp_option () {
    comp_option=""
    local Function_Local_comp_option
    case "${Var_Global_Build_comp_type}" in
        "gzip")
            Function_Local_comp_option() {
                local Var_Local_gzip_level Var_Local_gzip_window
                local Function_Local_gzip_level Function_Local_gzip_window

                Function_Local_gzip_level () {
                    msg_n "gzipの圧縮レベルを入力してください。 (1~22) : " "Enter the gzip compression level.  (1~22) : "
                    read -r Var_Local_gzip_level
                    if ! [[ ${Var_Local_gzip_level} -lt 23 && ${Var_Local_gzip_level} -ge 1 ]]; then
                        Function_Local_gzip_level
                        return 0
                    fi
                }
                Function_Local_gzip_window () {
                    msg_n \
                        "gzipのウィンドウサイズを入力してください。 (1~15) : " \
                        "Please enter the gzip window size. (1~15) : "

                    read -r Var_Local_gzip_window
                    if ! [[ ${Var_Local_gzip_window} -lt 15 && ${Var_Local_gzip_window} -ge 1 ]]; then
                        Function_Local_gzip_window
                        return 0
                    fi
                }
                Function_Local_gzip_level
                Function_Local_gzip_window
                comp_option="-Xcompression-level ${Var_Local_gzip_level} -Xwindow-size ${Var_Local_gzip_window}"
            }
            ;;
        "lz4")
            Function_Local_comp_option () {
                local Var_Local_lz4_high_comp
                msg_n \
                    "高圧縮モードを有効化しますか？ （y/N） : " \
                    "Do you want to enable high compression mode? （y/N） : "
                read -r Var_Local_lz4_high_comp
                case "${Var_Local_lz4_high_comp}" in
                    "y" | "Y" | "yes" | "Yes" | "YES" ) comp_option="-Xhc"         ;;
                    "n" | "N" | "no"  | "No"  | "NO"  ) :                          ;;
                    *                                 ) Function_Local_comp_option ;;
                esac
            }
            ;;
        "zstd")
            Function_Local_comp_option () {
                local Var_Local_zstd_level
                msg_n \
                    "zstdの圧縮レベルを入力してください。 (1~22) : " \
                    "Enter the zstd compression level. (1~22) : "
                read -r Var_Local_zstd_level
                if [[ ${Var_Local_zstd_level} -lt 23 && ${Var_Local_zstd_level} -ge 1 ]]; then
                    comp_option="-Xcompression-level ${Var_Local_zstd_level}"
                else
                    Function_Local_comp_option
                fi
            }
            ;;
        "lzo")
            Function_Local_comp_option () {
                local Function_Local_lzo_algorithm Var_Local_lzo_algorithm
                Function_Local_lzo_algorithm () {
                    msg \
                        "lzoの圧縮アルゴリズムを以下の番号から選択して下さい" \
                        "Select the lzo compression algorithm from the numbers below"
                    msg \
                        "よく理解していない場合はlzo1x_999を選択して下さい" \
                        "Choose lzo1x_999 if you are not familiar with it"
                    echo
                    echo "1: lzo1x_1"
                    echo "2: lzo1x_1_11"
                    echo "3: lzo1x_1_12"
                    echo "4: lzo1x_1_15"
                    echo "5: lzo1x_999"
                    echo -n ": "
                    read -r Var_Local_lzo_algorithm
                    case "${Var_Local_lzo_algorithm}" in
                        "1" | "lzo1x_1")
                            Var_Local_lzo_algorithm="lzo1x_1"
                            ;;
                        "2" | "lzo1x_1_11")
                            Var_Local_lzo_algorithm="lzo1x_1_11"
                            ;;
                        "3" | "lzo1x_1_12")
                            Var_Local_lzo_algorithm="lzo1x_1_12"
                            ;;
                        "4" | "lzo1x_1_15")
                            Var_Local_lzo_algorithm="lzo1x_1_15"
                            ;;
                        "5" | "lzo1x_999")
                            Var_Local_lzo_algorithm="lzo1x_999"
                            ;;
                        *)
                            Function_Local_lzo_algorithm
                            return 0
                            ;;
                    esac
                }
                Function_Local_lzo_algorithm
                if [[ "${Var_Local_lzo_algorithm}" = "lzo1x_999" ]]; then                
                    local Function_Local_lzo_level Var_Local_lzo_level
                    Function_Local_lzo_level () {
                        msg_n "lzoの圧縮レベルを入力してください。 (1~9) : " "Enter the gzip compression level.  (1~9) : "
                        read -r Var_Local_lzo_level
                        if ! [[ ${Var_Local_lzo_level} -lt 10 && ${Var_Local_lzo_level} -ge 1 ]]; then
                            Function_Local_lzo_level
                            return 0
                        fi
                    }
                    Function_Local_lzo_level
                    comp_option="-Xalgorithm lzo1x_999 -Xcompression-level ${Var_Local_lzo_level}"
                else
                    comp_option="-Xalgorithm ${Var_Local_lzo_algorithm}"
                fi
            }
            ;;
        "xz")
            Function_Local_comp_option () {
                msg_error \
                    "現在${Var_Global_Build_comp_type}の詳細設定ウィザードがサポートされていません。" \
                    "The ${Var_Global_Build_comp_type} Advanced Wizard is not currently supported."
            }
            ;;
        "lzma" | *)
            Function_Local_comp_option () {
                :
            }
            ;;
    esac

    Function_Local_comp_option
}


Function_Global_Ask_username () {
    msg_n "ユーザー名を入力してください : " "Please enter your username : "
    read -r Var_Global_Build_username
    if [[ -z "${Var_Global_Build_username}" ]]; then
        Function_Global_Ask_username
        return 0
    fi
    return 0
}


Function_Global_Ask_password () {
    local Var_Local_password Var_Local_password_confirm

    msg_n "パスワードを入力してください : " "Please enter your password : "
    read -r -s Var_Local_password
    echo
    msg_n "もう一度入力して下さい : " "Type it again : "
    read -r -s Var_Local_password_confirm
    if [[ ! "${Var_Local_password}" = "${Var_Local_password_confirm}" ]]; then
        echo
        msg_error "同じパスワードが入力されませんでした。" "You did not enter the same password."
        Function_Global_Ask_password
    elif [[ -z "${Var_Local_password}" || -z "${Var_Local_password_confirm}" ]]; then
        echo
        msg_error "パスワードを入力してください。" "Please enter your password."
        Function_Global_Ask_password
    fi
    Var_Global_Build_password="${Var_Local_password}"
    echo
    return 0
}


Function_Global_Ask_kernel () {
    msg \
        "使用するカーネルを以下の番号から選択してください" \
        "Please select the kernel to use from the following numbers"

    #カーネルの一覧を取得
    local Var_Local_kernel_list
    #Var_Local_kernel_list=($("${Var_Global_Wizard_Env_script_path}/tools/kernel.sh" -a "${Var_Global_Wizard_Option_build_arch}" show))
    readarray -t Var_Local_kernel_list < <("${Var_Global_Wizard_Env_script_path}/tools/kernel.sh" -a "${Var_Global_Wizard_Option_build_arch}" show)

    #選択肢の生成
    local Var_Local_kernel Var_Local_count=1 Var_Local_int
    for Var_Local_kernel in "${Var_Local_kernel_list[@]}"; do
        (
            local kernel kernel_filename kernel_mkinitcpio_profile
            eval "$("${Var_Global_Wizard_Env_script_path}/tools/kernel.sh" -a "${Var_Global_Wizard_Option_build_arch}" get "${Var_Local_kernel}" )"
            echo -n "$(printf %02d "${Var_Local_count}")    ${kernel}"
            for Var_Local_int in $( seq 1 $(( 19 - ${#kernel} )) ); do echo -ne " "; done
            echo -ne "(${kernel_filename})\n"
        )
        Var_Local_count=$(( Var_Local_count + 1 ))
    done

    # 質問する
    echo -n ": "
    local Var_Local_input_kernel
    read -r Var_Local_input_kernel

    # 回答を解析する
    # 数字かどうか判定する
    set +e
    expr "${Var_Local_input_kernel}" + 1 >/dev/null 2>&1
    if [[ ${?} -lt 2 ]]; then
        set -e
        # 数字である
        Var_Local_input_kernel=$(( Var_Local_input_kernel - 1 ))
        if [[ -z "${Var_Local_kernel_list[${Var_Local_input_kernel}]}" ]]; then
            Function_Global_Ask_kernel
            return 0
        else
            Var_Global_Build_kernel="${Var_Local_kernel_list[${Var_Local_input_kernel}]}"
            
        fi
    else
        set -e
        # 数字ではない
        # 配列に含まれるかどうか判定
        if [[ ! $(printf '%s\n' "${Var_Local_kernel_list[@]}" | grep -qx "${Var_Local_input_kernel}"; echo -n ${?} ) -eq 0 ]]; then
            Function_Global_Ask_kernel
            return 0
        else
            Var_Global_Build_kernel="${Var_Local_input_kernel}"
        fi
    fi
}


# チャンネルの指定
Function_Global_Ask_channel () {
    # チャンネルの一覧を取得
    local Var_Local_int Var_Local_count=1 Var_Local_channel Var_Local_channel_list Var_Local_description Var_Local_channel_dir Var_Local_index
    #Var_Local_channel_list=($("${Var_Global_Wizard_Env_script_path}/tools/channel.sh" --nobuiltin show))
    #Var_Local_channel_dir=($("${Var_Global_Wizard_Env_script_path}/tools/channel.sh" --dirname --nobuiltin show))

    readarray -t Var_Local_channel_list < <("${Var_Global_Wizard_Env_script_path}/tools/channel.sh" --nobuiltin show)
    readarray -t Var_Local_channel_dir  < <("${Var_Global_Wizard_Env_script_path}/tools/channel.sh" --dirname --nobuiltin show)

    msg "チャンネルを以下の番号から選択してください。" "Select a channel from the numbers below."
    # 選択肢を生成
    for Var_Local_channel in "${Var_Local_channel_list[@]}"; do
        if [[ -f "${Var_Global_Wizard_Env_script_path}/channels/${Var_Local_channel_dir[$(( Var_Local_count - 1 ))]}/description.txt" ]]; then
            Var_Local_description=$(cat "${Var_Global_Wizard_Env_script_path}/channels/${Var_Local_channel_dir[$(( Var_Local_count - 1 ))]}/description.txt")
        else
            if [[ "${Var_Global_Wizard_Option_language}"  = "jp" ]]; then
                Var_Local_description="このチャンネルにはdescription.txtがありません。"
            else
                Var_Local_description="This channel does not have a description.txt."
            fi
        fi
        echo -ne "$(printf %02d "${Var_Local_count}")    ${Var_Local_channel}"
        for Var_Local_int in $( seq 1 $(( 19 - ${#Var_Local_channel} )) ); do echo -ne " "; done
        echo -ne "${Var_Local_description}\n"
        Var_Local_count="$(( Var_Local_count + 1 ))"
    done
    echo -n ":"
    read -r Var_Global_Build_channel

    # 入力された値が数字かどうか判定する
    set +e
    expr "${Var_Global_Build_channel}" + 1 >/dev/null 2>&1
    if (( ${?} == 0 )); then
        set -e
        # 数字である
        Var_Global_Build_channel=$(( Var_Global_Build_channel - 1))
        if [[ -z "${Var_Local_channel_list[${Var_Global_Build_channel}]}" ]]; then
            Function_Global_Ask_channel
            return 0
        else
            Var_Global_Build_channel="${Var_Local_channel_list[${Var_Global_Build_channel}]}"
        fi
    else
        set -e
        # 数字ではない
        if [[ ! $(printf '%s\n' "${Var_Local_channel_list[@]}" | grep -qx "${Var_Global_Build_channel}"; echo -n ${?} ) -eq 0 ]]; then
            Function_Global_Ask_channel
            return 0
        fi
    fi

    echo "${Var_Global_Build_channel}"

    return 0
}


# イメージファイルの所有者
Function_Global_Ask_owner () {
    local Function_Local_check_user
    Function_Local_check_user () {
        [[ -z "${1+SET}" ]] && return 2
        getent passwd "${1}" > /dev/null && return 0 || return 1
    }

    msg_n "イメージファイルの所有者を入力してください。: " "Enter the owner of the image file.: "
    read -r Var_Global_iso_owner
    if Function_Local_check_user "${Var_Global_iso_owner}"; then
        echo "ユーザーが存在しません。"
        Function_Global_Ask_owner
        return 0
    elif  [[ -z "${Var_Global_iso_owner}" ]]; then
        echo "ユーザー名を入力して下さい。"
        Function_Global_Ask_owner
        return 0
    elif [[ "${Var_Global_iso_owner}" = "root" ]]; then
        echo "所有者の変更を行いません。"
        return 0
    fi
}


# イメージファイルの作成先
Function_Global_Ask_out_dir () {
    msg "イメージファイルの作成先を入力して下さい。" "Enter the destination to create the image file."
    msg "デフォルトは ${Var_Global_Wizard_Env_script_path}/out です。" "The default is ${Var_Global_Wizard_Env_script_path}/out."
    echo -n ": "
    read -r out_dir
    if [[ -z "${out_dir}" ]]; then
        out_dir="${Var_Global_Wizard_Env_script_path}/out"
    else
        if [[ ! -d "${out_dir}" ]]; then
            msg_error \
                "存在しているディレクトリを指定して下さい。" \
                "Please specify the existing directory."
            Function_Global_Ask_out_dir
            return 0
        elif [[ "${out_dir}" = "/" ]] || [[ "${out_dir}" = "/home" ]]; then
            msg_error \
                "そのディレクトリは使用できません。" \
                "The directory is unavailable."
            Function_Global_Ask_out_dir
            return 0
        fi
    fi
}

Function_Global_Ask_tarball () {
    local Var_Local_input_yes_or_no
    msg_n "tarballをビルドしますか？[no]（y/N） : " "Build a tarball? [no] (y/N) : "
    read -r Var_Local_input_yes_or_no
    case "${Var_Local_input_yes_or_no}" in
        "y" | "Y" | "yes" | "Yes" | "YES" ) Var_Global_Build_tarball=true   ;;
        "n" | "N" | "no"  | "No"  | "NO"  ) Var_Global_Build_tarball=false  ;;
        *                                 ) Function_Global_Ask_tarball ;;
    esac
}


# 最終的なbuild.shのオプションを生成
Function_Global_Main_create_argument () {
    Var_Global_Build_argument=("--noconfirm" "-a" "${Var_Global_Wizard_Option_build_arch}")

    #[[ "${Var_Global_Build_japanese}" = true ]] && Var_Global_Build_argument+=("-l ja")
    [[ -n "${Var_Global_Build_locale}"       ]] && Var_Global_Build_argument+=("-l" "${Var_Global_Build_locale}")
    [[ "${Var_Global_Build_plymouth}" = true ]] && Var_Global_Build_argument+=("-b")
    [[ -n "${Var_Global_Build_comp_type}"    ]] && Var_Global_Build_argument+=("-c ${Var_Global_Build_comp_type}")
    [[ -n "${comp_option}"                   ]] && Var_Global_Build_argument+=("-t" "${comp_option}")
    [[ -n "${Var_Global_Build_kernel}"       ]] && Var_Global_Build_argument+=("-k" "${Var_Global_Build_kernel}")
    [[ -n "${Var_Global_Build_username}"     ]] && Var_Global_Build_argument+=("-u" "${Var_Global_Build_username}")
    [[ -n "${Var_Global_Build_password}"     ]] && Var_Global_Build_argument+=("-p" "${Var_Global_Build_password}")
    [[ -n "${out_dir}"                       ]] && Var_Global_Build_argument+=("-o" "${out_dir}")
    [[ "${Var_Global_Build_tarball}" = true  ]] && Var_Global_Build_argument+=("--tarball")
    #argument="--noconfirm -a ${Var_Global_Wizard_Option_build_arch} ${argument} ${Var_Global_Build_channel}"
    Var_Global_Build_argument+=("${Var_Global_Build_channel}")
}


# ビルド設定の確認
Function_Global_Ask_Confirm () {
    msg "以下の設定でビルドを開始します。" "Start the build with the following settings."
    echo
    #[[ -n "${Var_Global_Build_japanese}"           ]] && echo "           Japanese : ${Var_Global_Build_japanese}"
    [[ -n "${Var_Global_Build_locale}"             ]] && echo "           Language : ${Var_Global_Build_locale}"
    [[ -n "${Var_Global_Wizard_Option_build_arch}" ]] && echo "       Architecture : ${Var_Global_Wizard_Option_build_arch}"
    [[ -n "${Var_Global_Build_plymouth}"           ]] && echo "           Plymouth : ${Var_Global_Build_plymouth}"
    [[ -n "${Var_Global_Build_kernel}"             ]] && echo "             kernel : ${Var_Global_Build_kernel}"
    [[ -n "${Var_Global_Build_comp_type}"          ]] && echo " Compression method : ${Var_Global_Build_comp_type}"
    [[ -n "${comp_option}"                         ]] && echo "Compression options : ${comp_option}"
    [[ -n "${Var_Global_Build_username}"           ]] && echo "           Username : ${Var_Global_Build_username}"
    [[ -n "${Var_Global_Build_password}"           ]] && echo "           Password : ${Var_Global_Build_password}"
    [[ -n "${Var_Global_Build_channel}"            ]] && echo "            Channel : ${Var_Global_Build_channel}"
    echo
    msg_n \
        "この設定で続行します。よろしいですか？ (y/N) : " \
        "Continue with this setting. Is it OK? (y/N) : "
    local Var_Local_input_yes_or_no
    read -r Var_Local_input_yes_or_no
    case "${Var_Local_input_yes_or_no}" in
        "y" | "Y" | "yes" | "Yes" | "YES" ) :         ;;
        "n" | "N" | "no"  | "No"  | "NO"  ) exit 0    ;;
        *                                 ) Function_Global_Ask_Confirm ;;
    esac
}

Function_Global_Main_run_build.sh () {
    if [[ "${Var_Global_Wizard_Option_nobuild}" = true ]]; then
        echo "${argument}"
    else
        # build.shの引数を表示（デバッグ用）
        # echo ${argument}

        work_dir="${Var_Global_Wizard_Env_script_path}/work"
        sudo bash "${Var_Global_Wizard_Env_script_path}/build.sh" "${Var_Global_Build_argument[@]}"
        
    fi
}


Function_Global_Main_run_clean.sh() {
    sudo "${Var_Global_Wizard_Env_script_path}/tools/clean.sh -w ${work_dir}"
}


Function_Global_Main_set_iso_permission() {
    if [[ -n "${Var_Global_iso_owner}" ]]; then
        chown -R "${Var_Global_iso_owner}" "${out_dir}"
        chmod -R 750 "${out_dir}"
    fi
}

# 上の質問の関数を実行
Function_Global_Main_ask_questions () {
    Function_Global_Ask_build_arch
    Function_Global_Ask_plymouth
    Function_Global_Ask_kernel
    Function_Global_Ask_comp_type
    Function_Global_Ask_comp_option
    Function_Global_Ask_username
    Function_Global_Ask_password
    # Function_Global_Ask_japanese この関数はAlterISO2以前を想定されたものです。
    Function_Global_Ask_locale
    Function_Global_Ask_channel
    Function_Global_Ask_tarball

    # これらのディレクトリやファイルの所有権変更は現在無効化されています
    # Function_Global_Ask_owner
    # Function_Global_Ask_out_dir

    Function_Global_Ask_Confirm
}

Function_Global_Prebuild() {
    Function_Global_Main_wizard_language
    Function_Global_Main_check_required_files
    #Function_Global_Main_check_yay
    Function_Global_Main_load_default_config
    Function_Global_Main_install_dependent_packages
    Function_Global_Main_guide_to_the_web
    Function_Global_Main_run_keyring.sh
    Function_Global_Main_ask_questions
    Function_Global_Main_create_argument
}

Function_Global_Build() {
    Function_Global_Main_run_build.sh
}

Function_Global_PostBuild() {
    Function_Global_Main_remove_dependent_packages
    Function_Global_Main_run_clean.sh
    Function_Global_Main_set_iso_permission
}

Function_Global_Run() {
    Function_Global_Prebuild
    Function_Global_Build
    Function_Global_PostBuild
}

Function_Global_Run
