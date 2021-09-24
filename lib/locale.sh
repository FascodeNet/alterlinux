#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#
# /lib/locale.sh
#
# Functions for locale
#

_locale_list() {
    [[ -z "${arch-""}" ]] && exit 1
    grep -h -v ^'#' "${script_path}/system/locale-${arch}" | grep -v ^$ | cut -d " " -f 1
}

_locale_check() {
    _locale_list | grep -qx "${locale_name}"
}

_locale_get() {
    local _locale_config_line
    # 不正なロケール名なら終了する
    if ! _locale_check; then
        _msg_error "${locale_name} is not a valid language."
        exit 1
    fi

    # ロケール設定ファイルから該当の行を抽出
    readarray -t _locale_config_line < <( awk "{if(\$1 == \"${locale_name}\"){printf \$0\"\n\"}}" < "${script_path}/system/locale-${arch}" | tr " " "\n" | sed "/^$/d")

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
