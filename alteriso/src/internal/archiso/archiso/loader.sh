#!/usr/bin/env bash

__alteriso_profile_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
__alteriso_injectable="n"

__alteriso_loadfile() {
    local file="$1"
    if [[ -f "$file" ]]; then
        # shellcheck source=/dev/null
        source "$file"
    fi
}

__alteriso_injected_list() {
    local _funcs=()

    readarray -t _funcs < <(compgen -A function)

    local _f _f_org
    while read -r _f; do
        _f_org=$(echo "${_f}" | sed -E 's/^(pre|post|override)_(.+)$/\2/')
        if printf '%s\n' "${_funcs[@]}" | grep -qx "$_f_org"; then
            _msg_info "Injected function: $_f_org"
        fi

    done < <(printf '%s\n' "${_funcs[@]}" | grep -E '^(pre|post|override)_(.+)$' | sort -u)
}

__alteriso_cleanup() {
    unset __alteriso_profile_dir
}

# _run_onceのinjectのテストにおいて、メインターゲットとして呼び出されるダミー関数
alteriso_inject_test() {
    unset alteriso_inject_test
    unset pre_alteriso_inject_test
}

# pre_run_onceのinjectのテストにおいて、alteriso_inject_testの前に呼び出される関数
pre_alteriso_inject_test() {
    __alteriso_injectable="y"
}

# _run_onceをprofiledef.sh内で呼び出すための環境を整えるラッパー
__alteriso_run_once() {
    local _old_work_dir="${work_dir-""}"
    local _old_run_once_mode="${run_once_mode-""}"
    work_dir=$(mktemp -d)
    run_once_mode='alteriso_inject_test'
    _run_once "$1" || true
    run_once_mode="${_old_run_once_mode-""}"
    work_dir="${_old_work_dir-""}"
    rm -rf -- "${work_dir}"
}

# injectが可能かどうかテスト
__alteriso_run_once "alteriso_inject_test"
if [[ "$__alteriso_injectable" != "y" ]]; then
    echo "[alteriso] ERROR: This mkarchiso is not injectable." >&2
    exit 1
fi
