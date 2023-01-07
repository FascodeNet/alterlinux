#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#
# alteriso.sh
#
# AlterISO's own collection of functions
#


# gitコマンドのラッパー
# https://stackoverflow.com/questions/71901632/fatal-unsafe-repository-home-repon-is-owned-by-someone-else
# https://qiita.com/megane42/items/5375b54ea3570506e296
git(){
    command git config --global safe.directory "$script_path"
    command git "$@"
    command git config --global --unset safe.directory "$script_path"
}


# Create alteriso-info file
_make_alteriso_info(){
    # iso version info
    if [[ "${include_info}" = true ]]; then
        local _info_file="${isofs_dir}/alteriso-info"
        remove "${_info_file}"; touch "${_info_file}"
        _alteriso_info > "${_info_file}"
    fi
}

# Usage: getclm <number>
# 標準入力から値を受けとり、引数で指定された列を抽出します。
getclm() { cut -d " " -f "${1}"; }

# Usage: echo_blank <number>
# 指定されたぶんの半角空白文字を出力します
echo_blank(){ yes " " 2> /dev/null  | head -n "${1}" | tr -d "\n"; }

# cpコマンドのラッパー
_cp(){ cp -af --no-preserve=ownership,mode -- "${@}"; }

# Unmount helper Usage: _umount <target>
_umount() { mountpoint -q "${1}" && umount -lf "${1}"; return 0; }

# Mount helper Usage: _mount <source> <target>
_mount() { ! mountpoint -q "${2}" && [[ -f "${1}" ]] && [[ -d "${2}" ]] && mount "${1}" "${2}"; return 0; }

# Unmount work dir
umount_work () {
    local _args=("${build_dir}")
    [[ "${debug}" = true ]] && _args=("-d" "${_args[@]}")
    [[ "${nocolor}" = true ]] && _args+=("--nocolor")
    "${tools_dir}/umount.sh" "${_args[@]}"
}

# Mount airootfs on "${pacstrap_dir}"
mount_airootfs () {
    [[ ! -v pacstrap_dir ]] && return 0
    mkdir -p "${pacstrap_dir}"
    _mount "${pacstrap_dir}.img" "${pacstrap_dir}"
}

# Show message when file is removed
# remove <file> <file> ...
remove() {
    local _file
    for _file in "${@}"; do _msg_debug "Removing ${_file}"; rm -rf "${_file}"; done
}

# 強制終了時にアンマウント
umount_trap() {
    local _status="${?}"
    umount_work
    _msg_error "It was killed by the user.\nThe process may not have completed successfully."
    exit "${_status}"
}

# 設定ファイルを読み込む
# load_config [file1] [file2] ...
load_config() {
    local _file
    for _file in "${@}"; do [[ -f "${_file}" ]] && source "${_file}" && _msg_debug "The settings have been overwritten by the ${_file}"; done
    return 0
}

# Execute command for each module. It will be executed with {} replaced with the module name.
# for_module <command>
for_module(){ local module && for module in "${modules[@]}"; do eval "${@//"{}"/${module}}"; done; }

# chroot環境でpacmanコマンドを実行
# /etc/alteriso-pacman.confを準備してコマンドを実行します
_run_with_pacmanconf(){
    #cp "${build_dir}/${buildmode}.pacman.conf" "${pacstrap_dir}/etc/alteriso-pacman.conf"
    sed -e "s|^CacheDir|#CacheDir|g" "${build_dir}/${buildmode}.pacman.conf" > "${pacstrap_dir}/etc/alteriso-pacman.conf"
    "${@}"
    remove "${pacstrap_dir}/etc/alteriso-pacman.conf"
}

# コマンドをchrootで実行する
_chroot_run() {
    _msg_debug "Run command in chroot\nCommand: ${*}"
    arch-chroot "${pacstrap_dir}" "${@}" || return "${?}"
}

_mkimagechecksum() {
    _msg_info "Creating md5 checksum ..."
    echo "$(md5sum "${1}" | getclm 1) $(basename "${1}")" > "${1}.md5"
    _msg_info "Creating sha256 checksum ..."
    echo "$(sha256sum "${1}" | getclm 1) $(basename "${1}")" > "${1}.sha256"
}

# Check the value of a variable that can only be set to true or false.
check_bool() {
    local _value _variable
    for _variable in "${@}"; do
        _msg_debug -n "Checking ${_variable}..."
        eval ": \${${_variable}:=''}"
        _value="$(eval echo "\${${_variable},,}")"
        eval "${_variable}=${_value}"
        if [[ ! -v "${1}" ]] || [[ "${_value}"  = "" ]]; then
            [[ "${debug}" = true ]] && echo ; _msg_error "The variable name ${_variable} is empty." "1"
        elif [[ ! "${_value}" = "true" ]] && [[ ! "${_value}" = "false" ]]; then
            [[ "${debug}" = true ]] && echo ; _msg_error "The variable name ${_variable} is not of bool type (${_variable} = ${_value})" "1"
        elif [[ "${debug}" = true ]]; then
            echo -e " ${_value}"
        fi
    done
}

_run_cleansh(){
    bash "$([[ "${bash_debug}" = true ]] && echo -n "-x" || echo -n "+x")" "${tools_dir}/clean.sh" -o -w "$(realpath "${build_dir}")" "$([[ "${debug}" = true ]] && printf "%s" "-d")" "$([[ "${noconfirm}" = true ]] && printf "%s" "-n")" "$([[ "${nocolor}" = true ]] && printf "%s" "--nocolor")"
}

_usage () {
    cat "${script_path}/docs/build.sh/help.1"
    local blank="29" _arch _dirname _type _output _first _channel_dir
    for _type in "locale" "kernel"; do
        echo " ${_type} for each architecture:"
        for _arch in $(find "${script_path}/system/" -maxdepth 1 -mindepth 1 -name "${_type}-*" -print0 | xargs -I{} -0 basename {} | sed "s|${_type}-||g"); do
            echo "    ${_arch}$(echo_blank "$(( "${blank}" - "${#_arch}" ))")$(arch=${_arch} "_${_type}_list" | sed "/^$/d" | tr "\n" " ")"
        done
        echo
    done

    echo " Channel:"
    while read -r _channel_dir; do
        readarray -t _output < <(_channel_desc "${_channel_dir}")
        _first=true _dirname="$(basename "${_channel_dir}")"
        echo -n "    ${_dirname}"
        for _out in "${_output[@]}"; do
            "${_first}" && echo -e "    $(echo_blank "$(( "${blank}" - 4 - "${#_dirname}" ))")${_out}" || echo -e "    $(echo_blank "$(( "${blank}" + 5 - "${#_dirname}" ))")${_out}"
            _first=false
        done
    done < <(_channel_full_list)
    cat "${script_path}/docs/build.sh/help.2"
    [[ -n "${1:-}" ]] && exit "${1}"
}


## Check the build environment and create a directory.
prepare_env() {
    # Check work dir
    if [[ "${normwork}" = false ]]; then
        _msg_info "Deleting the contents of ${build_dir}..."
        _run_cleansh
    fi

    # Set gpg key
    if [[ -n "${gpg_key}" ]]; then
        gpg --batch --output "${work_dir}/pubkey.gpg" --export "${gpg_key}"
        exec {ARCHISO_GNUPG_FD}<>"${build_dir}/pubkey.gpg"
        export ARCHISO_GNUPG_FD
    fi

    # 強制終了時に作業ディレクトリを削除する
    local _trap_remove_work
    _trap_remove_work() {
        local status="${?}"
        [[ "${normwork}" = false ]] && echo && _run_cleansh
        exit "${status}"
    }
    trap '_trap_remove_work' HUP INT QUIT TERM

    return 0
}


# Error message
error_exit_trap(){
    local _exit="${?}" _line="${1}" && shift 1
    _msg_error "An exception error occurred in the function"
    _msg_error "Exit Code: ${_exit}\nLine: ${_line}\nArgument: ${ARGUMENT[*]}"
    exit "${_exit}"
}

# Preparation for build
prepare_build() {
    # Debug mode
    [[ "${bash_debug}" = true ]] && set -x -v

    # Show alteriso version
    [[ -n "${gitrev-""}" ]] && _msg_debug "The version of alteriso is ${gitrev}"

    # Load configs
    load_config "${channel_dir}/config.any" "${channel_dir}/config.${arch}"

    # Additional modules
    modules+=("${additional_modules[@]}")

    # Legacy mode
    if [[ "$(_channel_get_version "${channel_dir}")" = "3.0" ]]; then
        _msg_warn "The module cannot be used because it works with Alter ISO3.0 compatibility."
        modules=("legacy")
        legacy_mode=true
        [[ "${include_extra-"unset"}" = true ]] && modules=("legacy-extra")
    fi

    # Load presets
    local _modules=() module_check
    for_module '[[ -f "${preset_dir}/{}" ]] && readarray -t -O "${#_modules[@]}" _modules < <(grep -h -v ^'#' "${preset_dir}/{}") || _modules+=("{}")'
    modules=("${_modules[@]}")
    unset _modules

    # Ignore modules
    local _m
    for _m in "${exclude_modules[@]}"; do
        readarray -t modules < <(printf "%s\n" "${modules[@]}" | grep -xv "${_m}")
    done

    # Check modules
    readarray -t modules < <(printf "%s\n" "${modules[@]}" | awk '!a[$0]++')
    for_module "_module_check_with_msg {}"

    # Load modules
    for_module load_config "${module_dir}/{}/config.any" "${module_dir}/{}/config.${arch}"
    _msg_debug "Loaded modules: ${modules[*]}"
    ! printf "%s\n" "${modules[@]}" | grep -x "share" >/dev/null 2>&1 && _msg_warn "The share module is not loaded."
    ! printf "%s\n" "${modules[@]}" | grep -x "base" >/dev/null 2>&1 && _msg_error "The base module is not loaded." 1

    # Set kernel
    [[ "${customized_kernel}" = false ]] && kernel="${defaultkernel}"

    # Parse files
    eval "$(_locale_get)"
    eval "$(_kernel_get)"

    # Set username and password
    [[ "${customized_username}" = false ]] && username="${defaultusername}"
    [[ "${customized_password}" = false ]] && password="${defaultpassword}"

    # gitversion
    [[ ! -d "${script_path}/.git" ]] && [[ "${gitversion}" = true ]] && _msg_error "There is no git directory. You need to use git clone to use this feature." "1"
    [[ "${gitversion}" = true ]] && iso_version="${iso_version}-${gitrev}"

    # Generate tar file name
    tar_ext=""
    case "${tar_comp}" in
        "gzip" ) tar_ext="gz"                        ;;
        "zstd" ) tar_ext="zst"                       ;;
        "xz" | "lzo" | "lzma") tar_ext="${tar_comp}" ;;
    esac

    # Generate iso file name
    local _channel_name="${channel_name%.add}-${locale_version}" 
    iso_filename="${iso_name}-${_channel_name}-${iso_version}-${arch}.iso"
    tar_filename="${iso_filename%.iso}.tar.${tar_ext}"
    [[ "${nochname}" = true ]] && iso_filename="${iso_name}-${iso_version}-${arch}.iso"
    _msg_debug "Iso filename is ${iso_filename}"

    # check bool
    check_bool boot_splash cleaning noconfirm nodepend customized_username customized_password noloopmod nochname tarball noiso noaur customized_syslinux norescue_entry debug bash_debug nocolor msgdebug noefi nosigcheck gitversion

    # Check architecture for each channel
    #local _exit=0
    #bash "${tools_dir}/channel.sh" --version "${alteriso_version}" -a "${arch}" -n -b check "${channel_name}" || _exit="${?}"
    #( (( "${_exit}" != 0 )) && (( "${_exit}" != 1 )) ) && _msg_error "${channel_name} channel does not support current architecture (${arch})." "1"

    # Run with tee
    if [[ ! "${logging}" = false ]]; then
        [[ "${customized_logpath}" = false ]] && logging="${out_dir}/${iso_filename%.iso}.log"
        mkdir -p "$(dirname "${logging}")" && touch "${logging}"
        _msg_warn "Re-run sudo ${0} ${ARGUMENT[*]} --nodepend --nolog --nocolor --rerun 2>&1 | tee ${logging}"
        sudo "${0}" "${ARGUMENT[@]}" --nolog --nocolor --nodepend --rerun 2>&1 | tee "${logging}"
        exit "${PIPESTATUS[0]}"
    fi

    # Set argument of pkglist.sh
    pkglist_args=("-a" "${arch}" "-k" "${kernel}" "-c" "${channel_dir}" "-l" "${locale_name}" --line)
    [[ "${boot_splash}"              = true ]] && pkglist_args+=("-b")
    [[ "${debug}"                    = true ]] && pkglist_args+=("-d")
    [[ "${memtest86}"                = true ]] && pkglist_args+=("-m")
    [[ "${nocolor}"                  = true ]] && pkglist_args+=("--nocolor")
    (( "${#additional_exclude_pkg[@]}" >= 1 )) && pkglist_args+=("-e" "${additional_exclude_pkg[*]}")
    pkglist_args+=("${modules[@]}")

    # Set argument of aur.sh and pkgbuild.sh
    [[ "${bash_debug}"   = true ]] && makepkg_script_args+=("-x")
    [[ "${pacman_debug}" = true ]] && makepkg_script_args+=("-c")

    return 0
}

_make_pkgbuild() {
    # Get PKGBUILD List
    local _pkgbuild_dirs=("${channel_dir}/pkgbuild.any" "${channel_dir}/pkgbuild.${arch}")
    for_module '_pkgbuild_dirs+=("${module_dir}/{}/pkgbuild.any" "${module_dir}/{}/pkgbuild.${arch}")'

    # Copy PKGBUILD to work
    mkdir -p "${pacstrap_dir}/pkgbuilds/"
    for _dir in $(find "${_pkgbuild_dirs[@]}" -type f -name "PKGBUILD" -print0 2>/dev/null | xargs -0 -I{} realpath {} | xargs -I{} dirname {}); do
        _msg_info "Find $(basename "${_dir}")"
        _cp "${_dir}" "${pacstrap_dir}/pkgbuilds/"
    done
    
    # copy buold script
    _cp "${script_path}/system/pkgbuild.sh" "${pacstrap_dir}/root/pkgbuild.sh"

    # Run build script
    _run_with_pacmanconf _chroot_run "bash" "/root/pkgbuild.sh" "${makepkg_script_args[@]}" "/pkgbuilds"

    # Remove script
    remove "${pacstrap_dir}/root/pkgbuild.sh"

    return 0
}

