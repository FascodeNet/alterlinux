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
# Functions for kernel
#

_kernel_list() {
    local _list="${script_path}/system/kernel-${arch}" _file
    if [[ -v channel_dir ]]; then
        for _file in "${channel_dir}/kernel_list-${arch}" "${channel_dir}/kernel-${arch}"; do
            [[ -f "${_file}" ]] && _list="${_file}"
        done
    fi
    grep -h -v ^'#' "${_list}" | cut -d " " -f 1
}

_kernel_check() {
    _kernel_list | grep -qx "${kernel_name}"
}

_kernel_get() {
    #-- カーネルを解析、設定 --#
    local _kernel_config_file _kernel_config_line

    # 不正なカーネル名なら終了する
    if ! _kernel_check; then
        msg_error "Invalid kernel ${kernel_name}"
        exit 1
    fi

    # 設定ファイルを探す
    if [[ -f "${channel_dir}/kernel-${arch}" ]]; then
        _kernel_config_file="${channel_dir}/kernel-${arch}"
    else
        _kernel_config_file="${script_path}/system/kernel-${arch}"
    fi

    # カーネル設定ファイルから該当の行を抽出
    readarray -t _kernel_config_line < <(awk "{if(\$1 == \"${kernel_name}\"){printf \$0\"\n\"}}" < "${_kernel_config_file}" | tr " " "\n" | sed "/^$/d")

    # 抽出された行に書かれた設定をそれぞれの変数に代入
    # ここで定義された変数のみがグローバル変数
cat << EOF
kernel="${_kernel_config_line[0]}"
kernel_filename="${_kernel_config_line[1]}"
kernel_mkinitcpio_profile="${_kernel_config_line[2]}"
EOF
}
