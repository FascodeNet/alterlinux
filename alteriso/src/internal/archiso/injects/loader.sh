#!/usr/bin/env bash
# shellcheck disable=SC2154

__alteriso_profile_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
__alteriso_injectable="n"
__alteriso_compatible_mode="n"

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
            _msg_info "Injected function: $_f"
        fi

    done < <(printf '%s\n' "${_funcs[@]}" | grep -E '^(pre|post|override)_(.+)$' | sort -u)
}

__alteriso_cleanup() {
    # Clean up all variables starting with __alteriso_
    while read -r var; do
        unset "$var"
    done < <(compgen -v | grep '^__alteriso_')

    # Clean up all functions starting with __alteriso_
    while read -r func; do
        unset -f "$func"
    done < <(compgen -A function | grep '^__alteriso_')

    # Clean up all inject functions
    while read -r func; do
        unset -f "$func"
    done < <(compgen -A function | grep -E '^(pre|post|override)_(.+)$')
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

__alteriso_validate() {
    # injectが可能かどうかテスト
    __alteriso_run_once "alteriso_inject_test"
    if [[ "$__alteriso_injectable" != "y" ]]; then
        echo "[alteriso]  WARN: This mkarchiso is not injectable." >&2
        __alteriso_compatible_mode="y"
    fi

    # profiledef.jsonがあるかどうか
    if ! __alteriso_profiledef >/dev/null; then
        echo "[alteriso] ERROR: profiledef.json not found in ${__alteriso_profile_dir}" >&2
        __alteriso_compatible_mode="y"
    fi

    # jqがあるかどうか
    if [[ "$__alteriso_compatible_mode" = "n" ]] && ! command -v jq >/dev/null 2>&1; then
        echo "[alteriso] ERROR: 'jq' is required but not found. Please install 'jq'." >&2
        exit 1
    fi
}

__alteriso_validate_profile() {
    local _arch
    _arch=$(__alteriso_profiledef_arch)
    if [[ "$_arch" != "$arch" ]]; then
        echo "[alteriso] ERROR: Profile architecture ($_arch) does not match the current architecture ($arch)." >&2
        exit 1
    fi
}

__alteriso_profiledef() {
    local profiledef_json="${__alteriso_profile_dir}/profiledef.json"
    if [[ ! -f "$profiledef_json" ]]; then
        echo "[alteriso] ERROR: profiledef.json not found in ${__alteriso_profile_dir}" >&2
        exit 1
    fi

    cat "$profiledef_json"
}

__alteriso_profiledef_username() {
    __alteriso_profiledef | jq -r ".username"
}

__alteriso_profiledef_kernelname() {
    __alteriso_profiledef | jq -r ".kernel_name"
}

__alteriso_profiledef_arch() {
    __alteriso_profiledef | jq -r ".arch"
}

__alteriso_profiledef_modules() {
    __alteriso_profiledef | jq -r '.modules[]'
}

__alteriso_show_config() {
    if [[ "$__alteriso_compatible_mode" = "y" ]]; then
        return 0
    fi

    local _username _kernel_name _arch
    _username=$(__alteriso_profiledef_username)
    _kernel_name=$(__alteriso_profiledef_kernelname)
    _arch=$(__alteriso_profiledef_arch)

    echo "[alteriso] INFO:              Architecture:   $_arch"
    echo "[alteriso] INFO:                  Username:   $_username"
    echo "[alteriso] INFO:               Kernel Name:   $_kernel_name"
    echo "[alteriso] INFO:         Profile Directory:   $__alteriso_profile_dir"

    echo -n "[alteriso] Are you sure to continue? (y/N): "
    read -r answer
    if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
        echo "[alteriso] Aborted."
        exit 0
    fi
}
__alteriso_validate
__alteriso_show_config
if [[ "$__alteriso_compatible_mode" = "y" ]]; then
    echo "[alteriso] INFO: Running in compatible mode. Injection features are disabled." >&2
    __alteriso_cleanup
    return 0
fi
