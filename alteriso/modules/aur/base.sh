#!/usr/bin/env bash
# shellcheck disable=SC2154

__alteriso_add_validator __alteriso_aur_validate

__alteriso_aur_has_sources() {
    local _target_arch
    _target_arch=$(__alteriso_arch)
    local _pkgbuild_dir="${__alteriso_profile_dir}/pkgbuild"

    local _package_file
    for _package_file in \
        "${__alteriso_profile_dir}/packages_aur.${_target_arch}" \
        "${__alteriso_profile_dir}/bootstrap_packages_aur.${_target_arch}"; do
        [[ -f "$_package_file" ]] && grep -q '[^[:space:]]' "$_package_file" && return 0
    done
    [[ -d "$_pkgbuild_dir" ]] && find "$_pkgbuild_dir" -mindepth 1 -maxdepth 1 -type d -print -quit | grep -q .
}

__alteriso_aur_validate() {
    __alteriso_aur_has_sources || return 0

    local _ayaka=${ALTERISO_AYAKA:-ayaka}
    if ! command -v "$_ayaka" >/dev/null 2>&1; then
        echo "[alteriso] ERROR: Ayaka is required to build AUR and local PKGBUILD packages: $_ayaka" >&2
        exit 1
    fi
}

__alteriso_aur_add_repo() {
    local _pacman_conf="$1"
    local _repo_name="$2"
    local _repo_dir="$3"
    local _updated_conf
    _updated_conf=$(mktemp "${_pacman_conf}.XXXXXX")

    awk -v repo_name="$_repo_name" -v repo_dir="$_repo_dir" '
        function repository() {
            print "[" repo_name "]"
            print "SigLevel = Optional TrustAll"
            print "Server = file://" repo_dir
            print ""
        }
        /^\[/ && $0 != "[options]" && !added {
            repository()
            added = 1
        }
        { print }
        END {
            if (!added) {
                print ""
                repository()
            }
        }
    ' "$_pacman_conf" >"$_updated_conf"
    mv -- "$_updated_conf" "$_pacman_conf"
}

__alteriso_aur_append_packages() {
    local _package _existing
    for _package in "$@"; do
        for _existing in "${buildmode_pkg_list[@]}"; do
            [[ "$_existing" != "$_package" ]] || continue 2
        done
        buildmode_pkg_list+=("$_package")
    done
}

__alteriso_aur_cleanup() {
    if [[ "${__alteriso_aur_exit_trap_installed-}" == "y" ]]; then
        trap - EXIT
    fi
    if [[ -n "${__alteriso_aur_pacman_conf_backup-}" && -f "$__alteriso_aur_pacman_conf_backup" ]]; then
        mv -- "$__alteriso_aur_pacman_conf_backup" "$__alteriso_aur_pacman_conf"
    fi
    if [[ -n "${__alteriso_aur_repo_dir-}" && "$__alteriso_aur_repo_dir" == "${work_dir}/alteriso-local-"* ]]; then
        rm -rf -- "$__alteriso_aur_repo_dir"
        rm -f -- "${__alteriso_aur_repo_dir}.lock"
    fi
    if [[ -n "${__alteriso_aur_manifest-}" && "$__alteriso_aur_manifest" == "${work_dir}/alteriso-local-"* ]]; then
        rm -f -- "$__alteriso_aur_manifest" "${__alteriso_aur_manifest}.lock"
    fi
    unset __alteriso_aur_exit_trap_installed __alteriso_aur_manifest
    unset __alteriso_aur_pacman_conf __alteriso_aur_pacman_conf_backup
    unset __alteriso_aur_repo_dir __alteriso_aur_repo_name
}

__alteriso_aur_cleanup_on_exit() {
    local _status=$?
    __alteriso_aur_cleanup
    if (( _status != 0 )); then
        rm -f -- "${work_dir}/${run_once_mode}.pre__make_packages"
    fi
    exit "$_status"
}

__alteriso_aur_build_packages() {
    local _ayaka=${ALTERISO_AYAKA:-ayaka}
    local _arch _package_file
    _arch=$(__alteriso_arch)
    if [[ "$buildmode" == "bootstrap" ]]; then
        _package_file="${__alteriso_profile_dir}/bootstrap_packages_aur.${_arch}"
    else
        _package_file="${__alteriso_profile_dir}/packages_aur.${_arch}"
    fi
    local _pkgbuild_dir="${__alteriso_profile_dir}/pkgbuild"
    if ! { [[ -f "$_package_file" ]] && grep -q '[^[:space:]]' "$_package_file"; } \
        && ! { [[ -d "$_pkgbuild_dir" ]] && find "$_pkgbuild_dir" -mindepth 1 -maxdepth 1 -type d -print -quit | grep -q .; }; then
        return 0
    fi
    local _suffix _database _source _configured_repositories
    local _packages=() _sources=() _install=() _args=()

    __alteriso_aur_pacman_conf="${work_dir}/${buildmode}.pacman.conf"
    __alteriso_aur_pacman_conf_backup="${__alteriso_aur_pacman_conf}.alteriso-aur"
    _configured_repositories=$(pacman-conf --config "$__alteriso_aur_pacman_conf" --repo-list)
    while :; do
        if ! _suffix=$(od -An -N8 -tx1 /dev/urandom); then
            _msg_error "Failed to generate a local repository name." 1
        fi
        _suffix=${_suffix//[[:space:]]/}
        if [[ ${#_suffix} -ne 16 ]]; then
            _msg_error "Failed to generate a local repository name." 1
        fi
        __alteriso_aur_repo_name="alteriso-local-${_suffix}"
        __alteriso_aur_repo_dir="${work_dir}/${__alteriso_aur_repo_name}-${buildmode}-${_arch}"
        __alteriso_aur_manifest="${work_dir}/${__alteriso_aur_repo_name}-${buildmode}-${_arch}.json"
        if ! grep -Fxq -- "$__alteriso_aur_repo_name" <<<"$_configured_repositories" \
            && [[ ! -e "$__alteriso_aur_repo_dir" && ! -e "$__alteriso_aur_manifest" ]]; then
            break
        fi
    done

    if [[ -f "$_package_file" ]]; then
        readarray -t _packages < <(sed -e '/^[[:space:]]*$/d' "$_package_file")
    fi
    if [[ -d "$_pkgbuild_dir" ]]; then
        while IFS= read -r -d '' _source; do
            _sources+=("$_source")
        done < <(find "$_pkgbuild_dir" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
    fi

    _args=(
        build
        "${_packages[@]}"
        --arch "$_arch"
        --pacman-conf "$__alteriso_aur_pacman_conf"
        --repo "$__alteriso_aur_repo_name"
        --output "$__alteriso_aur_repo_dir"
        --manifest "$__alteriso_aur_manifest"
        --work-dir "${work_dir}/ayaka"
        --makepkg-option '!debug'
    )
    for _source in "${_sources[@]}"; do
        _args+=(--local-source "$_source")
    done

    _msg_info "Building AUR and local PKGBUILD packages with Ayaka..."
    if ! "$_ayaka" "${_args[@]}"; then
        __alteriso_aur_cleanup
        _msg_error "Ayaka failed to build AUR and local PKGBUILD packages." 1
    fi

    if ! jq -e \
        --arg arch "$_arch" \
        --arg name "$__alteriso_aur_repo_name" \
        --arg repo "$__alteriso_aur_repo_dir" \
        '.schema_version == 1
            and .arch == $arch
            and .repository.name == $name
            and .repository.path == $repo
            and (.repository.database | type == "string")
            and (.install | type == "array")
            and all(.install[]; type == "string" and length > 0)' \
        "$__alteriso_aur_manifest" >/dev/null; then
        local _invalid_manifest="$__alteriso_aur_manifest"
        __alteriso_aur_cleanup
        _msg_error "Ayaka produced an invalid build manifest: $_invalid_manifest" 1
    fi

    _database=$(jq -r '.repository.database' "$__alteriso_aur_manifest")
    if [[ "$_database" != "${__alteriso_aur_repo_dir}/"* || ! -f "$_database" ]]; then
        __alteriso_aur_cleanup
        _msg_error "Ayaka manifest references an invalid repository database: $_database" 1
    fi

    readarray -t _install < <(jq -r '.install[]' "$__alteriso_aur_manifest")
    cp --preserve=mode -- "$__alteriso_aur_pacman_conf" "$__alteriso_aur_pacman_conf_backup"
    __alteriso_aur_add_repo "$__alteriso_aur_pacman_conf" "$__alteriso_aur_repo_name" "$__alteriso_aur_repo_dir"
    __alteriso_aur_append_packages "${_install[@]}"
    if [[ -z "$(trap -p EXIT)" ]]; then
        __alteriso_aur_exit_trap_installed=y
        trap '__alteriso_aur_cleanup_on_exit' EXIT
    fi
    _msg_info "AUR and local PKGBUILD packages are ready."
}
