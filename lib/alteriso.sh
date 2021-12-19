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


# Base installation (airootfs)
_make_basefs() {
    _msg_info "Creating ext4 image of 32GiB..."
    truncate -s 32G -- "${pacstrap_dir}.img"
    mkfs.ext4 -O '^has_journal,^resize_inode' -E 'lazy_itable_init=0' -m 0 -F -- "${pacstrap_dir}.img" 32G
    tune2fs -c "0" -i "0" "${pacstrap_dir}.img"
    _msg_info "Done!"

    _msg_info "Mounting ${pacstrap_dir}.img on ${pacstrap_dir}"
    mount_airootfs
    _msg_info "Done!"
    return 0
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
    cp "${build_dir}/${buildmode}.pacman.conf" "${pacstrap_dir}/etc/alteriso-pacman.conf"
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


# Check the build environment and create a directory.
prepare_env() {
    # Check packages
    if [[ "${nodepend}" = false ]]; then
        local _check_failed=false _pkg _result=0
        _msg_info "Checking dependencies ..."
        ! pacman -Qq pyalpm > /dev/null 2>&1 && _msg_error "pyalpm is not installed." 1
        for _pkg in "${dependence[@]}"; do
            eval "${tools_dir}/package.py" "${_pkg}" "$( [[ "${debug}" = false ]] && echo "> /dev/null")" || _result="${?}"
            if (( _result == 3 )) || (( _result == 4 )); then
                _check_failed=true
            fi
            _result=0
        done
        [[ "${_check_failed}" = true ]] && exit 1
    fi

    # Load loop kernel module
    if [[ "${noloopmod}" = false ]]; then
        [[ ! -d "/usr/lib/modules/$(uname -r)" ]] && _msg_error "The currently running kernel module could not be found.\nProbably the system kernel has been updated.\nReboot your system to run the latest kernel." "1"
        lsmod | getclm 1 | grep -qx "loop" || modprobe loop
    fi

    # Check work dir
    if [[ "${normwork}" = false ]]; then
        _msg_info "Deleting the contents of ${build_dir}..."
        _run_cleansh
    fi

    # Debug mode
    [[ "${bash_debug}" = true ]] && set -x -v

    # Show alteriso version
    [[ -n "${gitrev-""}" ]] && _msg_debug "The version of alteriso is ${gitrev}"

    # Set bootloader type
    [[ "${boot_splash}" = true ]] && use_bootloader_type="splash" && not_use_bootloader_type="nosplash"

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

    # Check modules
    readarray -t modules < <(printf "%s\n" "${modules[@]}" | awk '!a[$0]++')
    for_module "_module_check_with_msg {}"

    # Load modules
    for_module load_config "${module_dir}/{}/config.any" "${module_dir}/{}/config.${arch}"
    _msg_debug "Loaded modules: ${modules[*]}"
    ! printf "%s\n" "${modules[@]}" | grep -x "share" >/dev/null 2>&1 && _msg_warn "The share module is not loaded."
    ! printf "%s\n" "${modules[@]}" | grep -x "base" >/dev/null 2>&1 && msg_error "The base module is not loaded." 1

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

    # Generate iso file name
    local _channel_name="${channel_name%.add}-${locale_version}" 
    iso_filename="${iso_name}-${_channel_name}-${iso_version}-${arch}.iso"
    tar_filename="${iso_filename%.iso}.tar.gz"
    [[ "${nochname}" = true ]] && iso_filename="${iso_name}-${iso_version}-${arch}.iso"
    _msg_debug "Iso filename is ${iso_filename}"

    # check bool
    check_bool boot_splash cleaning noconfirm nodepend customized_username customized_password noloopmod nochname tarball noiso noaur customized_syslinux norescue_entry debug bash_debug nocolor msgdebug noefi nosigcheck gitversion

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

    # Set bootmodes
    { [[ "${tarball}" = true ]] && ! printf "%s\n" "${buildmodes[@]}" | grep -qx "bootstrap"; } && buildmodes+=("tarball")
    [[ "${noiso}" = true ]] && readarray -t buildmodes < <(printf "%s\n" "${buildmodes[@]}" | grep -xv "iso")

    # Set squashfs option
    airootfs_image_tool_options=(-noappend -comp "${sfs_comp}" "${sfs_comp_opt[@]}")

    _msg_info "Done build preparation!"
}

#-- AlterISO 3.1 functions --#
# これらの関数は現在実行されません。それぞれの関数はAlterISO 4.0への移植後に削除してください。



# Build airootfs filesystem image
make_prepare() {
    mount_airootfs

    # Create packages list
    _msg_info "Creating a list of installed packages on live-enviroment..."
    pacman-key --init
    pacman -Q --sysroot "${pacstrap_dir}" | tee "${isofs_dir}/${install_dir}/pkglist.${arch}.txt" "${build_dir}/packages-full.list" > /dev/null

    # Cleanup
    remove "${pacstrap_dir}/root/optimize_for_tarball.sh"
    _cleanup_pacstrap_dir

    # Create squashfs
    mkdir -p -- "${isofs_dir}/${install_dir}/${arch}"
    _msg_info "Creating SquashFS image, this may take some time..."
    mksquashfs "${pacstrap_dir}" "${build_dir}/iso/${install_dir}/${arch}/airootfs.sfs" -noappend -comp "${sfs_comp}" "${sfs_comp_opt[@]}"

    # Create checksum
    _msg_info "Creating checksum file for self-test..."
    echo "$(sha512sum "${isofs_dir}/${install_dir}/${arch}/airootfs.sfs" | getclm 1) airootfs.sfs" > "${isofs_dir}/${install_dir}/${arch}/airootfs.sha512"
    _msg_info "Done!"

    # Sign with gpg
    if [[ -v gpg_key ]] && (( "${#gpg_key}" != 0 )); then
        _msg_info "Creating signature file ($gpg_key) ..."
        cd -- "${isofs_dir}/${install_dir}/${arch}"
        gpg --detach-sign --default-key "${gpg_key}" "airootfs.sfs"
        cd -- "${OLDPWD}"
        _msg_info "Done!"
    fi

    umount_work

    [[ "${cleaning}" = true ]] && remove "${pacstrap_dir}" "${pacstrap_dir}.img"

    return 0
}

# Add files to the root of isofs
make_overisofs() {
    local _over_isofs_list _isofs
    _over_isofs_list=("${channel_dir}/over_isofs.any""${channel_dir}/over_isofs.${arch}")
    for_module '_over_isofs_list+=("${module_dir}/{}/over_isofs.any" "${module_dir}/{}/over_isofs.${arch}")'
    for _isofs in "${_over_isofs_list[@]}"; do
        [[ -d "${_isofs}" ]] && [[ -n "$(find "${_isofs}" -mindepth 1 -maxdepth 2)" ]] &&  cp -af "${_isofs}"/* "${isofs_dir}"
    done

    return 0
}

_make_aur() {
    readarray -t _pkglist_aur < <("${tools_dir}/pkglist.sh" --aur "${pkglist_args[@]}")
    _pkglist_aur=("${_pkglist_aur[@]}" "${norepopkg[@]}")
    _aursh_args=(
        "-a" "${aur_helper_command}" -e "${aur_helper_package}"
        "-d" "$(printf "%s\n" "${aur_helper_depends[@]}" | tr "\n" ",")"
        "-p" "$(printf "%s\n" "${_pkglist_aur[@]}" | tr "\n" ",")"
        "${makepkg_script_args[@]}" -- "${aur_helper_args[@]}"
    )

    # Create a list of packages to be finally installed as packages.list directly under the working directory.
    echo -e "\n# AUR packages.\n#\n" >> "${build_dir}/packages.list"
    printf "%s\n" "${_pkglist_aur[@]}" >> "${build_dir}/packages.list"

    # prepare for yay
    cp -rf --preserve=mode "${script_path}/system/aur.sh" "${pacstrap_dir}/root/aur.sh"

    # Unset TMPDIR to work around https://bugs.archlinux.org/task/70580
    # --asdepsをつけているのでaur.shで削除される --neededをつけているので明示的にインストールされている場合削除されない
    local _pacstrap_args=()
    [[ "${pacman_debug}" = true ]] && _pacstrap_args+=("--debug")
    _pacstrap_args=("${aur_helper_depend[@]}")
    if [[ "${quiet}" = "y" ]]; then
        env -u TMPDIR pacstrap -C "${build_dir}/${buildmode}.pacman.conf" -c -G -M -- "${pacstrap_dir}" --asdeps --needed "${_pacstrap_args[@]}" &> /dev/null
    else
        env -u TMPDIR pacstrap -C "${build_dir}/${buildmode}.pacman.conf" -c -G -M -- "${pacstrap_dir}" --asdeps --needed "${_pacstrap_args[@]}"
    fi

    # Run aur script
    _run_with_pacmanconf _chroot_run "bash" "/root/aur.sh" "${_aursh_args[@]}"

    # Remove script
    remove "${pacstrap_dir}/root/aur.sh"

    _msg_info "Done! Packages installed successfully."
}

_make_pkgbuild() {
    # Get PKGBUILD List
    local _pkgbuild_dirs=("${channel_dir}/pkgbuild.any" "${channel_dir}/pkgbuild.${arch}")
    for_module '_pkgbuild_dirs+=("${module_dir}/{}/pkgbuild.any" "${module_dir}/{}/pkgbuild.${arch}")'

    # Copy PKGBUILD to work
    mkdir -p "${pacstrap_dir}/pkgbuilds/"
    for _dir in $(find "${_pkgbuild_dirs[@]}" -type f -name "PKGBUILD" -print0 2>/dev/null | xargs -0 -I{} realpath {} | xargs -I{} dirname {}); do
        _msg_info "Find $(basename "${_dir}")"
        cp -r "${_dir}" "${pacstrap_dir}/pkgbuilds/"
    done
    
    # copy buold script
    cp -rf --preserve=mode "${script_path}/system/pkgbuild.sh" "${pacstrap_dir}/root/pkgbuild.sh"

    # Run build script
    _run_with_pacmanconf _chroot_run "bash" "/root/pkgbuild.sh" "${makepkg_script_args[@]}" "/pkgbuilds"

    # Remove script
    remove "${pacstrap_dir}/root/pkgbuild.sh"

    _msg_info "Done! Packages built successfully."
}
