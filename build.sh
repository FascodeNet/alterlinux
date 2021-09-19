#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#
# build.sh
#
# The main script that runs the build
#

set -Eeu

# Internal config
# Do not change these values.
script_path="$( cd -P "$( dirname "$(readlink -f "${0}")" )" && pwd )"
defaultconfig="${script_path}/default.conf"
tools_dir="${script_path}/tools"
module_dir="${script_path}/modules"
customized_username=false
customized_password=false
customized_kernel=false
customized_logpath=false
pkglist_args=()
makepkg_script_args=()
modules=()
DEFAULT_ARGUMENT=""
ARGUMENT=("${@}")
alteriso_version="3.1"
norepopkg=()
legacy_mode=false
rerun=false
use_bootloader_type="nosplash"
not_use_bootloader_type="splash"


#-- AlterISO 4.0 Variables --#
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
buildmodes=("iso") # buildmodes=("iso" "netboot" "bootstrap")
pacman_conf="/etc/pacman.conf"
airootfs_image_type="squashfs"
declare -A file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
)
quiet=n
app_name="AlterISO"
# adapted from GRUB_EARLY_INITRD_LINUX_STOCK in https://git.savannah.gnu.org/cgit/grub.git/tree/util/grub-mkconfig.in
readonly ucodes=('intel-uc.img' 'intel-ucode.img' 'amd-uc.img' 'amd-ucode.img' 'early_ucode.cpio' 'microcode.cpio')

# Load config file
[[ ! -f "${defaultconfig}" ]] && "${tools_dir}/msg.sh" -a 'build.sh' error "${defaultconfig} was not found." && exit 1
for config in "${defaultconfig}" "${script_path}/custom.conf"; do
    [[ -f "${config}" ]] && source "${config}" && loaded_files+=("${config}")
done

# Control the environment
umask 0022
export LC_ALL="C"
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-"$(date +%s)"}"

# Message common function
# msg_common [type] [-n] [string]
msg_common(){
    local _msg_opts=("-a" "build.sh") _type="${1}" && shift 1
    [[ "${1}" = "-n" ]] && _msg_opts+=("-o" "-n") && shift 1
    [[ "${msgdebug}" = true ]] && _msg_opts+=("-x")
    [[ "${nocolor}"  = true ]] && _msg_opts+=("-n")
    _msg_opts+=("${_type}" "${@}")
    "${tools_dir}/msg.sh" "${_msg_opts[@]}"
}

# Show an INFO message
# ${1}: message string
_msg_info() { msg_common info "${@}"; }

# Show an Warning message
# ${1}: message string
_msg_warn() { msg_common warn "${@}"; }

# Show an debug message
# ${1}: message string
_msg_debug() { 
    [[ "${debug}" = true ]] && msg_common debug "${@}" || return 0
}

# Show an ERROR message then exit with status
# ${1}: message string
# ${2}: exit code number (with 0 does not exit)
_msg_error() {
    msg_common error "${1}"
    { [[ -n "${2:-""}" ]] && (( "${2}" > 0 )); } && exit "${2}" || return 0
}


# Usage: getclm <number>
# 標準入力から値を受けとり、引数で指定された列を抽出します。
getclm() { cut -d " " -f "${1}"; }

# Usage: echo_blank <number>
# 指定されたぶんの半角空白文字を出力します
echo_blank(){ yes " " 2> /dev/null  | head -n "${1}" | tr -d "\n"; }

_usage () {
    cat "${script_path}/docs/build.sh/help.1"
    local blank="29" _arch _dirname _type _output _first
    for _type in "locale" "kernel"; do
        echo " ${_type} for each architecture:"
        for _arch in $(find "${script_path}/system/" -maxdepth 1 -mindepth 1 -name "${_type}-*" -print0 | xargs -I{} -0 basename {} | sed "s|${_type}-||g"); do
            echo "    ${_arch}$(echo_blank "$(( "${blank}" - "${#_arch}" ))")$("${tools_dir}/${_type}.sh" -a "${_arch}" show)"
        done
        echo
    done

    echo " Channel:"
    for _dirname in $(bash "${tools_dir}/channel.sh" --version "${alteriso_version}" -d -b -n --line show | sed "s|.add$||g"); do
        readarray -t _output < <("${tools_dir}/channel.sh" --version "${alteriso_version}" --nocheck desc "${_dirname}")
        _first=true
        echo -n "    ${_dirname}"
        for _out in "${_output[@]}"; do
            "${_first}" && echo -e "    $(echo_blank "$(( "${blank}" - 4 - "${#_dirname}" ))")${_out}" || echo -e "    $(echo_blank "$(( "${blank}" + 5 - "${#_dirname}" ))")${_out}"
            _first=false
        done
    done
    cat "${script_path}/docs/build.sh/help.2"
    [[ -n "${1:-}" ]] && exit "${1}"
}

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

# Display channel list
show_channel_list() {
    local _args=("-v" "${alteriso_version}" show)
    [[ "${nochkver}" = true ]] && _args+=("-n")
    bash "${tools_dir}/channel.sh" "${_args[@]}"
}

# Execute command for each module. It will be executed with {} replaced with the module name.
# for_module <command>
for_module(){ local module && for module in "${modules[@]}"; do eval "${@//"{}"/${module}}"; done; }

# pacstrapを実行
_pacstrap(){
    _msg_info "Installing packages to ${pacstrap_dir}/'..."
    local _args=("-c" "-G" "-M" "--" "${pacstrap_dir}" "${@}")
    [[ "${pacman_debug}" = true ]] && _args+=(--debug)
    pacstrap -C "${build_dir}/pacman.conf" "${_args[@]}"
    _msg_info "Packages installed successfully!"
}

# chroot環境でpacmanコマンドを実行
# /etc/alteriso-pacman.confを準備してコマンドを実行します
_run_with_pacmanconf(){
    cp "${build_dir}/${buildmode}.pacman.conf" "${pacstrap_dir}/etc/alteriso-pacman.conf"
    eval -- "${@}"
    remove "${pacstrap_dir}/etc/alteriso-pacman.conf"
}

# コマンドをchrootで実行する
_chroot_run() {
    _msg_debug "Run command in chroot\nCommand: ${*}"
    arch-chroot "${pacstrap_dir}" "${@}" || return "${?}"
}

_cleanup_common () {
    _msg_info "Cleaning up what we can on airootfs..."

    # Delete pacman database sync cache files (*.tar.gz)
    [[ -d "${pacstrap_dir}/var/lib/pacman" ]] && find "${pacstrap_dir}/var/lib/pacman" -maxdepth 1 -type f -delete

    # Delete pacman database sync cache
    [[ -d "${pacstrap_dir}/var/lib/pacman/sync" ]] && find "${pacstrap_dir}/var/lib/pacman/sync" -delete

    # Delete pacman package cache
    [[ -d "${pacstrap_dir}/var/cache/pacman/pkg" ]] && find "${pacstrap_dir}/var/cache/pacman/pkg" -type f -delete

    # Delete all log files, keeps empty dirs.
    [[ -d "${pacstrap_dir}/var/log" ]] && find "${pacstrap_dir}/var/log" -type f -delete

    # Delete all temporary files and dirs
    [[ -d "${pacstrap_dir}/var/tmp" ]] && find "${pacstrap_dir}/var/tmp" -mindepth 1 -delete

    # Delete package pacman related files.
    find "${build_dir}" \( -name '*.pacnew' -o -name '*.pacsave' -o -name '*.pacorig' \) -delete

    # Delete all cache file
    [[ -d "${pacstrap_dir}/var/cache" ]] && find "${pacstrap_dir}/var/cache" -mindepth 1 -delete

    # Create an empty /etc/machine-id
    printf '' > "${pacstrap_dir}/etc/machine-id"

    _msg_info "Done!"
}

# Cleanup airootfs
_cleanup_pacstrap_dir() {
    _msg_info "Cleaning up in pacstrap location..."

    # Delete all files in /boot
    [[ -d "${pacstrap_dir}/boot" ]] && find "${pacstrap_dir}/boot" -mindepth 1 -delete
    # Delete pacman database sync cache files (*.tar.gz)
    [[ -d "${pacstrap_dir}/var/lib/pacman" ]] && find "${pacstrap_dir}/var/lib/pacman" -maxdepth 1 -type f -delete
    # Delete pacman database sync cache
    [[ -d "${pacstrap_dir}/var/lib/pacman/sync" ]] && find "${pacstrap_dir}/var/lib/pacman/sync" -delete
    # Delete pacman package cache
    [[ -d "${pacstrap_dir}/var/cache/pacman/pkg" ]] && find "${pacstrap_dir}/var/cache/pacman/pkg" -type f -delete
    # Delete all log files, keeps empty dirs.
    [[ -d "${pacstrap_dir}/var/log" ]] && find "${pacstrap_dir}/var/log" -type f -delete
    # Delete all temporary files and dirs
    [[ -d "${pacstrap_dir}/var/tmp" ]] && find "${pacstrap_dir}/var/tmp" -mindepth 1 -delete
    # Delete package pacman related files.
    find "${work_dir}" \( -name '*.pacnew' -o -name '*.pacsave' -o -name '*.pacorig' \) -delete
    # Create an empty /etc/machine-id
    rm -f -- "${pacstrap_dir}/etc/machine-id"
    printf '' > "${pacstrap_dir}/etc/machine-id"

    _msg_info "Done!"
}

_cleanup_airootfs(){
    _cleanup_common
    # Delete all files in /boot
    [[ -d "${pacstrap_dir}/boot" ]] && find "${pacstrap_dir}/boot" -mindepth 1 -delete
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

# Show settings.
show_settings() {
    if [[ "${boot_splash}" = true ]]; then
        _msg_info "Boot splash is enabled."
        _msg_info "Theme is used ${theme_name}."
    fi
    _msg_info "Language is ${locale_fullname}."
    _msg_info "Use the ${kernel} kernel."
    _msg_info "Live username is ${username}."
    _msg_info "Live user password is ${password}."
    _msg_info "The compression method of squashfs is ${sfs_comp}."
    _msg_info "Use the ${channel_name%.add} channel."
    _msg_info "Build with architecture ${arch}."
    (( "${#additional_exclude_pkg[@]}" != 0 )) && _msg_info "Excluded packages: ${additional_exclude_pkg[*]}"
    if [[ "${noconfirm}" = false ]]; then
        echo -e "\nPress Enter to continue or Ctrl + C to cancel."
        read -r
    fi
    trap HUP INT QUIT TERM
    trap 'umount_trap' HUP INT QUIT TERM
    trap 'error_exit_trap $LINENO' ERR

    return 0
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
    if [[ "$(bash "${tools_dir}/channel.sh" --version "${alteriso_version}" ver "${channel_name}")" = "3.0" ]]; then
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
    module_check(){
        _msg_debug -n "Checking ${1} module ... "
        bash "${tools_dir}/module.sh" check "${1}" || _msg_error "Module ${1} is not available." "1" && echo "${module_dir}/${1}"
    }
    readarray -t modules < <(printf "%s\n" "${modules[@]}" | awk '!a[$0]++')
    for_module "module_check {}"

    # Load modules
    for_module load_config "${module_dir}/{}/config.any" "${module_dir}/{}/config.${arch}"
    _msg_debug "Loaded modules: ${modules[*]}"
    ! printf "%s\n" "${modules[@]}" | grep -x "share" >/dev/null 2>&1 && _msg_warn "The share module is not loaded."

    # Set kernel
    [[ "${customized_kernel}" = false ]] && kernel="${defaultkernel}"

    # Parse files
    eval "$(bash "${tools_dir}/locale.sh" -s -a "${arch}" get "${locale_name}")"
    eval "$(bash "${tools_dir}/kernel.sh" -s -c "${channel_name}" -a "${arch}" get "${kernel}")"

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
    local _exit=0
    bash "${tools_dir}/channel.sh" --version "${alteriso_version}" -a "${arch}" -n -b check "${channel_name}" || _exit="${?}"
    ( (( "${_exit}" != 0 )) && (( "${_exit}" != 1 )) ) && _msg_error "${channel_name} channel does not support current architecture (${arch})." "1"

    # Run with tee
    if [[ ! "${logging}" = false ]]; then
        [[ "${customized_logpath}" = false ]] && logging="${out_dir}/${iso_filename%.iso}.log"
        mkdir -p "$(dirname "${logging}")" && touch "${logging}"
        _msg_warn "Re-run sudo ${0} ${ARGUMENT[*]} --nodepend --nolog --nocolor --rerun 2>&1 | tee ${logging}"
        sudo "${0}" "${ARGUMENT[@]}" --nolog --nocolor --nodepend --rerun 2>&1 | tee "${logging}"
        exit "${?}"
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
    [[ "${pacman_debug}" = true ]] && makepkg_script_args+=("-d")

    # Set bootloader type
    [[ "${boot_splash}" = true ]] && use_bootloader_type="splash" && not_use_bootloader_type="nosplash"

    return 0
}

# Prepare /${install_dir}/boot/syslinux
make_syslinux() {
    mkdir -p "${isofs_dir}/syslinux"

    # 一時ディレクトリに設定ファイルをコピー
    mkdir -p "${build_dir}/syslinux/"
    cp -a "${script_path}/syslinux/"* "${build_dir}/syslinux/"
    [[ -d "${channel_dir}/syslinux" ]] && [[ "${customized_syslinux}" = true ]] && cp -af "${channel_dir}/syslinux"* "${build_dir}/syslinux/"

    # copy all syslinux config to work dir
    for _cfg in "${build_dir}/syslinux/"*.cfg; do
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
             s|%OS_NAME%|${os_name}|g;
             s|%KERNEL_FILENAME%|${kernel_filename}|g;
             s|%ARCH%|${arch}|g;
             s|%INSTALL_DIR%|${install_dir}|g" "${_cfg}" > "${isofs_dir}/syslinux/${_cfg##*/}"
    done

    # Replace the SYSLINUX configuration file with or without boot splash.
    local _use_config_name="nosplash" _no_use_config_name="splash" _pxe_or_sys
    if [[ "${boot_splash}" = true ]]; then
        _use_config_name=splash
        _no_use_config_name=nosplash
    fi
    for _pxe_or_sys in "sys" "pxe"; do
        remove "${isofs_dir}/syslinux/archiso_${_pxe_or_sys}_${_no_use_config_name}.cfg"
        mv "${isofs_dir}/syslinux/archiso_${_pxe_or_sys}_${_use_config_name}.cfg" "${isofs_dir}/syslinux/archiso_${_pxe_or_sys}.cfg"
    done

    # Set syslinux wallpaper
    cp "${script_path}/syslinux/splash.png" "${isofs_dir}/syslinux"
    [[ -f "${channel_dir}/splash.png" ]] && cp -f "${channel_dir}/splash.png" "${isofs_dir}/syslinux"

    # remove config
    local _remove_config
    function _remove_config() {
        remove "${isofs_dir}/syslinux/${1}"
        sed -i "s|$(grep "${1}" "${isofs_dir}/syslinux/archiso_sys_load.cfg")||g" "${isofs_dir}/syslinux/archiso_sys_load.cfg" 
    }

    [[ "${norescue_entry}" = true  ]] && _remove_config archiso_sys_rescue.cfg
    [[ "${memtest86}"      = false ]] && _remove_config memtest86.cfg

    # copy files
    cp "${pacstrap_dir}/usr/lib/syslinux/bios/"*.c32 "${isofs_dir}/syslinux"
    cp "${pacstrap_dir}/usr/lib/syslinux/bios/lpxelinux.0" "${isofs_dir}/syslinux"
    cp "${pacstrap_dir}/usr/lib/syslinux/bios/memdisk" "${isofs_dir}/syslinux"


    if [[ -e "${isofs_dir}/syslinux/hdt.c32" ]]; then
        install -d -m 0755 -- "${isofs_dir}/syslinux/hdt"
        if [[ -e "${pacstrap_dir}/usr/share/hwdata/pci.ids" ]]; then
            gzip -c -9 "${pacstrap_dir}/usr/share/hwdata/pci.ids" > "${isofs_dir}/syslinux/hdt/pciids.gz"
        fi
        find "${pacstrap_dir}/usr/lib/modules" -name 'modules.alias' -print -exec gzip -c -9 '{}' ';' -quit > "${isofs_dir}/syslinux/hdt/modalias.gz"
    fi

    return 0
}

# Prepare /isolinux
make_isolinux() {
    install -d -m 0755 -- "${isofs_dir}/syslinux"
    sed "s|%INSTALL_DIR%|${install_dir}|g" "${script_path}/system/isolinux.cfg" > "${isofs_dir}/syslinux/isolinux.cfg"
    install -m 0644 -- "${pacstrap_dir}/usr/lib/syslinux/bios/isolinux.bin" "${isofs_dir}/syslinux/"
    install -m 0644 -- "${pacstrap_dir}/usr/lib/syslinux/bios/isohdpfx.bin" "${isofs_dir}/syslinux/"

    return 0
}

# Prepare /EFI
make_efi() {
    local _bootfile _use_config_name="nosplash" _efi_config_list=() _efi_config
    [[ "${boot_splash}" = true ]] && _use_config_name="splash"
    _bootfile="$(basename "$(ls "${pacstrap_dir}/usr/lib/systemd/boot/efi/systemd-boot"*".efi" )")"

    install -d -m 0755 -- "${isofs_dir}/EFI/boot"
    install -m 0644 -- "${pacstrap_dir}/usr/lib/systemd/boot/efi/${_bootfile}" "${isofs_dir}/EFI/boot/${_bootfile#systemd-}"

    install -d -m 0755 -- "${isofs_dir}/loader/entries"
    sed "s|%ARCH%|${arch}|g;" "${script_path}/efiboot/${_use_config_name}/loader.conf" > "${isofs_dir}/loader/loader.conf"

    readarray -t _efi_config_list < <(find "${script_path}/efiboot/${_use_config_name}/" -mindepth 1 -maxdepth 1 -type f -name "archiso-usb*.conf" -printf "%f\n" | grep -v "rescue")
    [[ "${norescue_entry}" = false ]] && readarray -t _efi_config_list < <(find "${script_path}/efiboot/${_use_config_name}/" -mindepth 1 -maxdepth 1 -type f  -name "archiso-usb*.conf" -printf "%f\n")

    for _efi_config in "${_efi_config_list[@]}"; do
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
            s|%OS_NAME%|${os_name}|g;
            s|%KERNEL_FILENAME%|${kernel_filename}|g;
            s|%ARCH%|${arch}|g;
            s|%INSTALL_DIR%|${install_dir}|g" \
        "${script_path}/efiboot/${_use_config_name}/${_efi_config}" > "${isofs_dir}/loader/entries/$(basename "${_efi_config}" | sed "s|usb|${arch}|g")"
    done

    # edk2-shell based UEFI shell
    local _efi_shell_arch
    if [[ -d "${pacstrap_dir}/usr/share/edk2-shell" ]]; then
        for _efi_shell_arch in $(find "${pacstrap_dir}/usr/share/edk2-shell" -mindepth 1 -maxdepth 1 -type d -print0 | xargs -0 -I{} basename {}); do
            if [[ -f "${pacstrap_dir}/usr/share/edk2-shell/${_efi_shell_arch}/Shell_Full.efi" ]]; then
                cp "${pacstrap_dir}/usr/share/edk2-shell/${_efi_shell_arch}/Shell_Full.efi" "${isofs_dir}/EFI/shell_${_efi_shell_arch}.efi"
            elif [[ -f "${pacstrap_dir}/usr/share/edk2-shell/${_efi_shell_arch}/Shell.efi" ]]; then
                cp "${pacstrap_dir}/usr/share/edk2-shell/${_efi_shell_arch}/Shell.efi" "${isofs_dir}/EFI/shell_${_efi_shell_arch}.efi"
            else
                continue
            fi
            echo -e "title  UEFI Shell ${_efi_shell_arch}\nefi    /EFI/shell_${_efi_shell_arch}.efi" > "${isofs_dir}/loader/entries/uefi-shell-${_efi_shell_arch}.conf"
        done
    fi

    return 0
}

# Prepare efiboot.img::/EFI for "El Torito" EFI boot mode
make_efiboot() {
    truncate -s 128M "${build_dir}/efiboot.img"
    mkfs.fat -n ARCHISO_EFI "${build_dir}/efiboot.img"

    mkdir -p "${build_dir}/efiboot"
    mount "${build_dir}/efiboot.img" "${build_dir}/efiboot"

    mkdir -p "${build_dir}/efiboot/EFI/alteriso/${arch}" "${build_dir}/efiboot/EFI/boot" "${build_dir}/efiboot/loader/entries"
    cp "${isofs_dir}/${install_dir}/boot/${arch}/${kernel_filename}" "${build_dir}/efiboot/EFI/alteriso/${arch}/${kernel_filename}.efi"
    cp "${isofs_dir}/${install_dir}/boot/${arch}/archiso.img" "${build_dir}/efiboot/EFI/alteriso/${arch}/archiso.img"

    local _ucode_image _efi_config _use_config_name="nosplash" _bootfile
    for _ucode_image in "${pacstrap_dir}/boot/"{intel-uc.img,intel-ucode.img,amd-uc.img,amd-ucode.img,early_ucode.cpio,microcode.cpio}; do
        [[ -e "${_ucode_image}" ]] && cp "${_ucode_image}" "${build_dir}/efiboot/EFI/alteriso/"
    done

    cp "${pacstrap_dir}/usr/share/efitools/efi/HashTool.efi" "${build_dir}/efiboot/EFI/boot/"

    _bootfile="$(basename "$(ls "${pacstrap_dir}/usr/lib/systemd/boot/efi/systemd-boot"*".efi" )")"
    cp "${pacstrap_dir}/usr/lib/systemd/boot/efi/${_bootfile}" "${build_dir}/efiboot/EFI/boot/${_bootfile#systemd-}"

    [[ "${boot_splash}" = true ]] && _use_config_name="splash"
    sed "s|%ARCH%|${arch}|g;" "${script_path}/efiboot/${_use_config_name}/loader.conf" > "${build_dir}/efiboot/loader/loader.conf"

    find "${isofs_dir}/loader/entries/" -maxdepth 1 -mindepth 1 -name "uefi-shell*" -type f -printf "%p\0" | xargs -0 -I{} cp {} "${build_dir}/efiboot/loader/entries/"

    readarray -t _efi_config_list < <(find "${script_path}/efiboot/${_use_config_name}/" -mindepth 1 -maxdepth 1 -type f -name "archiso-cd*.conf" -printf "%f\n" | grep -v "rescue")
    [[ "${norescue_entry}" = false ]] && readarray -t _efi_config_list < <(find "${script_path}/efiboot/${_use_config_name}/" -mindepth 1 -maxdepth 1 -type f  -name "archiso-cd*.conf" -printf "%f\n")

    for _efi_config in "${_efi_config_list[@]}"; do
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
            s|%OS_NAME%|${os_name}|g;
            s|%KERNEL_FILENAME%|${kernel_filename}|g;
            s|%ARCH%|${arch}|g;
            s|%INSTALL_DIR%|${install_dir}|g" \
        "${script_path}/efiboot/${_use_config_name}/${_efi_config}" > "${build_dir}/efiboot/loader/entries/$(basename "${_efi_config}" | sed "s|cd|${arch}|g")"
    done

    find "${isofs_dir}/EFI" -maxdepth 1 -mindepth 1 -name "shell*.efi" -printf "%p\0" | xargs -0 -I{} cp {} "${build_dir}/efiboot/EFI/"
    umount -d "${build_dir}/efiboot"

    return 0
}

# Compress tarball
make_tarball() {
    # backup airootfs.img for tarball
    _msg_debug "Tarball filename is ${tar_filename}"
    _msg_info "Copying airootfs.img ..."
    cp "${pacstrap_dir}.img" "${pacstrap_dir}.img.org"

    # Run script
    mount_airootfs
    [[ -f "${pacstrap_dir}/root/optimize_for_tarball.sh" ]] && _chroot_run "bash /root/optimize_for_tarball.sh -u ${username}"
    _cleanup_common
    _chroot_run "mkinitcpio -P"
    remove "${pacstrap_dir}/root/optimize_for_tarball.sh"

    # make
    tar_comp_opt+=("--${tar_comp}")
    mkdir -p "${out_dir}"
    _msg_info "Creating tarball..."
    cd -- "${pacstrap_dir}"
    _msg_debug "Run tar -c -v -p -f \"${out_dir}/${tar_filename}\" ${tar_comp_opt[*]} ./*"
    tar -c -v -p -f "${out_dir}/${tar_filename}" "${tar_comp_opt[@]}" ./*
    cd -- "${OLDPWD}"

    # checksum
    _mkimagechecksum "${out_dir}/${tar_filename}"
    _msg_info "Done! | $(ls -sh "${out_dir}/${tar_filename}")"

    remove "${pacstrap_dir}.img"
    mv "${pacstrap_dir}.img.org" "${pacstrap_dir}.img"

    [[ "${noiso}" = true ]] && _msg_info "The password for the live user and root is ${password}."
    
    return 0
}


# Build airootfs filesystem image
make_prepare() {
    mount_airootfs

    # Create packages list
    _msg_info "Creating a list of installed packages on live-enviroment..."
    pacman-key --init
    pacman -Q --sysroot "${pacstrap_dir}" | tee "${isofs_dir}/${install_dir}/pkglist.${arch}.txt" "${build_dir}/packages-full.list" > /dev/null

    # Cleanup
    remove "${pacstrap_dir}/root/optimize_for_tarball.sh"
    _cleanup_airootfs

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

make_alteriso_info(){
    # iso version info
    if [[ "${include_info}" = true ]]; then
        local _info_file="${isofs_dir}/alteriso-info" _version="${iso_version}"
        remove "${_info_file}"; touch "${_info_file}"
        [[ -d "${script_path}/.git" ]] && [[ "${gitversion}" = false ]] && _version="${iso_version}-${gitrev}"
        "${tools_dir}/alteriso-info.sh" -a "${arch}" -b "${boot_splash}" -c "${channel_name%.add}" -d "${iso_publisher}" -k "${kernel}" -o "${os_name}" -p "${password}" -u "${username}" -v "${_version}" -m "$(printf "%s," "${modules[@]}")" > "${_info_file}"
    fi

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

#-- AlterISO 3.2 functions --#
# Shows configuration options.
_show_config() {
    local build_date
    build_date="$(date --utc --iso-8601=seconds -d "@${SOURCE_DATE_EPOCH}")"
    _msg_info "${app_name} configuration settings"
    _msg_info "             Architecture:   ${arch}"
    _msg_info "        Working directory:   ${work_dir}"
    _msg_info "   Installation directory:   ${install_dir}"
    _msg_info "               Build date:   ${build_date}"
    _msg_info "         Output directory:   ${out_dir}"
    _msg_info "       Current build mode:   ${buildmode}"
    _msg_info "              Build modes:   ${buildmodes[*]}"
    _msg_info "                  GPG key:   ${gpg_key:-None}"
    _msg_info "               GPG signer:   ${gpg_sender:-None}"
    _msg_info "Code signing certificates:   ${cert_list[*]}"
    _msg_info "                  Profile:   ${channel_name}"
    _msg_info "Pacman configuration file:   ${pacman_conf}"
    _msg_info "          Image file name:   ${image_name:-None}"
    _msg_info "         ISO volume label:   ${iso_label}"
    _msg_info "            ISO publisher:   ${iso_publisher}"
    _msg_info "          ISO application:   ${iso_application}"
    _msg_info "               Boot modes:   ${bootmodes[*]}"
    #_msg_info "            Packages File:   ${buildmode_packages}"
    #_msg_info "                 Packages:   ${buildmode_pkg_list[*]}"
}

# Cleanup airootfs
_cleanup_pacstrap_dir() {
    _msg_info "Cleaning up in pacstrap location..."

    # Delete all files in /boot
    [[ -d "${pacstrap_dir}/boot" ]] && find "${pacstrap_dir}/boot" -mindepth 1 -delete
    # Delete pacman database sync cache files (*.tar.gz)
    [[ -d "${pacstrap_dir}/var/lib/pacman" ]] && find "${pacstrap_dir}/var/lib/pacman" -maxdepth 1 -type f -delete
    # Delete pacman database sync cache
    [[ -d "${pacstrap_dir}/var/lib/pacman/sync" ]] && find "${pacstrap_dir}/var/lib/pacman/sync" -delete
    # Delete pacman package cache
    [[ -d "${pacstrap_dir}/var/cache/pacman/pkg" ]] && find "${pacstrap_dir}/var/cache/pacman/pkg" -type f -delete
    # Delete all log files, keeps empty dirs.
    [[ -d "${pacstrap_dir}/var/log" ]] && find "${pacstrap_dir}/var/log" -type f -delete
    # Delete all temporary files and dirs
    [[ -d "${pacstrap_dir}/var/tmp" ]] && find "${pacstrap_dir}/var/tmp" -mindepth 1 -delete
    # Delete package pacman related files.
    find "${work_dir}" \( -name '*.pacnew' -o -name '*.pacsave' -o -name '*.pacorig' \) -delete
    # Create an empty /etc/machine-id
    rm -f -- "${pacstrap_dir}/etc/machine-id"
    printf '' > "${pacstrap_dir}/etc/machine-id"

    _msg_info "Done!"
}

# Create a squashfs image and place it in the ISO 9660 file system.
# $@: options to pass to mksquashfs
_run_mksquashfs() {
    local image_path="${isofs_dir}/${install_dir}/${arch}/airootfs.sfs"
    rm -f -- "${image_path}"
    if [[ "${quiet}" == "y" ]]; then
        mksquashfs "$@" "${image_path}" -noappend "${airootfs_image_tool_options[@]}" -no-progress > /dev/null
    else
        mksquashfs "$@" "${image_path}" -noappend "${airootfs_image_tool_options[@]}"
    fi
}

# Create an ext4 image containing the root file system and pack it inside a squashfs image.
# Save the squashfs image on the ISO 9660 file system.
_mkairootfs_ext4+squashfs() {
    local ext4_hash_seed mkfs_ext4_options=()
    [[ -e "${pacstrap_dir}" ]] || _msg_error "The path '${pacstrap_dir}' does not exist" 1

    _msg_info "Creating ext4 image of 32 GiB and copying '${pacstrap_dir}/' to it..."

    ext4_hash_seed="$(uuidgen --sha1 --namespace 93a870ff-8565-4cf3-a67b-f47299271a96 \
        --name "${SOURCE_DATE_EPOCH} ext4 hash seed")"
    mkfs_ext4_options=(
        '-d' "${pacstrap_dir}"
        '-O' '^has_journal,^resize_inode'
        '-E' "lazy_itable_init=0,root_owner=0:0,hash_seed=${ext4_hash_seed}"
        '-m' '0'
        '-F'
        '-U' 'clear'
    )
    [[ ! "${quiet}" == "y" ]] || mkfs_ext4_options+=('-q')
    rm -f -- "${pacstrap_dir}.img"
    E2FSPROGS_FAKE_TIME="${SOURCE_DATE_EPOCH}" mkfs.ext4 "${mkfs_ext4_options[@]}" -- "${pacstrap_dir}.img" 32G
    tune2fs -c 0 -i 0 -- "${pacstrap_dir}.img" > /dev/null
    _msg_info "Done!"

    install -d -m 0755 -- "${isofs_dir}/${install_dir}/${arch}"
    _msg_info "Creating SquashFS image, this may take some time..."
    _run_mksquashfs "${pacstrap_dir}.img"
    _msg_info "Done!"
    rm -- "${pacstrap_dir}.img"
}

# Create a squashfs image containing the root file system and saves it on the ISO 9660 file system.
_mkairootfs_squashfs() {
    [[ -e "${pacstrap_dir}" ]] || _msg_error "The path '${pacstrap_dir}' does not exist" 1

    install -d -m 0755 -- "${isofs_dir}/${install_dir}/${arch}"
    _msg_info "Creating SquashFS image, this may take some time..."
    _run_mksquashfs "${pacstrap_dir}"
}

# Create an EROFS image containing the root file system and saves it on the ISO 9660 file system.
_mkairootfs_erofs() {
    local fsuuid
    [[ -e "${pacstrap_dir}" ]] || _msg_error "The path '${pacstrap_dir}' does not exist" 1

    install -d -m 0755 -- "${isofs_dir}/${install_dir}/${arch}"
    local image_path="${isofs_dir}/${install_dir}/${arch}/airootfs.erofs"
    rm -f -- "${image_path}"
    # Generate reproducible file system UUID from SOURCE_DATE_EPOCH
    fsuuid="$(uuidgen --sha1 --namespace 93a870ff-8565-4cf3-a67b-f47299271a96 --name "${SOURCE_DATE_EPOCH}")"
    _msg_info "Creating EROFS image, this may take some time..."
    mkfs.erofs -U "${fsuuid}" "${airootfs_image_tool_options[@]}" -- "${image_path}" "${pacstrap_dir}"
    _msg_info "Done!"
}

# Create checksum file for the rootfs image.
_mkchecksum() {
    _msg_info "Creating checksum file for self-test..."
    cd -- "${isofs_dir}/${install_dir}/${arch}"
    if [[ -e "${isofs_dir}/${install_dir}/${arch}/airootfs.sfs" ]]; then
        sha512sum airootfs.sfs > airootfs.sha512
    elif [[ -e "${isofs_dir}/${install_dir}/${arch}/airootfs.erofs" ]]; then
        sha512sum airootfs.erofs > airootfs.sha512
    fi
    cd -- "${OLDPWD}"
    _msg_info "Done!"
}

# GPG sign the root file system image.
_mksignature() {
    local airootfs_image_filename gpg_options=()
    _msg_info "Signing rootfs image..."
    if [[ -e "${isofs_dir}/${install_dir}/${arch}/airootfs.sfs" ]]; then
        airootfs_image_filename="${isofs_dir}/${install_dir}/${arch}/airootfs.sfs"
    elif [[ -e "${isofs_dir}/${install_dir}/${arch}/airootfs.erofs" ]]; then
        airootfs_image_filename="${isofs_dir}/${install_dir}/${arch}/airootfs.erofs"
    fi
    rm -f -- "${airootfs_image_filename}.sig"
    # Add gpg sender option if the value is provided
    [[ -z "${gpg_sender}" ]] || gpg_options+=('--sender' "${gpg_sender}")
    # always use the .sig file extension, as that is what mkinitcpio-archiso's hooks expect
    gpg --batch --no-armor --no-include-key-block --output "${airootfs_image_filename}.sig" --detach-sign \
        --default-key "${gpg_key}" "${gpg_options[@]}" "${airootfs_image_filename}"
    _msg_info "Done!"
}

# Helper function to run functions only one time.
# $1: function name
_run_once() {
    if [[ ! -e "${lockfile_dir}/${run_once_mode}.${1}" ]]; then
        umount_work
        _msg_debug "Running ${1} ..."
        mount_airootfs
        "${@}"
        mkdir -p "${lockfile_dir}" ; touch "${lockfile_dir}/${run_once_mode}.${1}"
    else
        _msg_debug "Skipped because ${1} has already been executed."
    fi
}

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

# Set up custom pacman.conf with custom cache and pacman hook directories.
_make_pacman_conf() {
    local _cache_dirs _system_cache_dirs _profile_cache_dirs _pacman_conf
    local _pacman_conf_list=("${script_path}/pacman-${arch}.conf" "${channel_dir}/pacman-${arch}.conf" "${script_path}/system/pacman-${arch}.conf")

    # Pacman configuration file used only when building
    # If there is pacman.conf for each channel, use that for building
    for _pacman_conf in "${_pacman_conf_list[@]}"; do
        if [[ -f "${_pacman_conf}" ]]; then
            pacman_conf="${_pacman_conf}"
            break
        fi
    done
    _msg_debug "Use ${pacman_conf}"

    _msg_info "Copying custom pacman.conf to work directory..."
    _msg_info "Using pacman CacheDir: ${cache_dir}"
    # take the profile pacman.conf and strip all settings that would break in chroot when using pacman -r
    # append CacheDir and HookDir to [options] section
    # HookDir is *always* set to the airootfs' override directory
    # see `man 8 pacman` for further info
    pacman-conf --config "${pacman_conf}" | \
        sed "/CacheDir/d;/DBPath/d;/HookDir/d;/LogFile/d;/RootDir/d;/\[options\]/a CacheDir = ${cache_dir}
        /\[options\]/a HookDir = ${pacstrap_dir}/etc/pacman.d/hooks/" > "${build_dir}/${buildmode}.pacman.conf"


    #[[ "${nosigcheck}" = true ]] && sed -ir "s|^s*SigLevel.+|SigLevel = Never|g" "${pacman_conf}"

    #[[ -n "$(find "${cache_dir}" -maxdepth 1 -name '*.pkg.tar.*' 2> /dev/null)" ]] && _msg_info "Use cached package files in ${cache_dir}"
}

# Prepare working directory and copy custom root file system files.
_make_custom_airootfs() {
    local passwd=() _airootfs_list=()
    local filename permissions

    for_module '_airootfs_list+=("${module_dir}/{}/airootfs.any" "${module_dir}/{}/airootfs.${arch}")'
    _airootfs_list+=("${channel_dir}/airootfs.any" "${channel_dir}/airootfs.${arch}")

    install -d -m 0755 -o 0 -g 0 -- "${pacstrap_dir}"

    for _airootfs in "${_airootfs_list[@]}";do
        if [[ -d "${_airootfs}" ]]; then
            _msg_info "Copying ${_airootfs}..."
            cp -af --no-preserve=ownership,mode -- "${_airootfs}/." "${pacstrap_dir}"
        fi
    done

    # Replace /etc/mkinitcpio.conf if Plymouth is enabled.
    #if [[ "${boot_splash}" = true ]]; then
    #    cp -f "${script_path}/mkinitcpio/mkinitcpio-plymouth.conf" "${airootfs_dir}/etc/mkinitcpio.conf"
    #else
    #    cp -f "${script_path}/mkinitcpio/mkinitcpio.conf" "${airootfs_dir}/etc/mkinitcpio.conf"
    #fi

    # Set ownership and mode for files and directories
    for filename in "${!file_permissions[@]}"; do
        IFS=':' read -ra permissions <<< "${file_permissions["${filename}"]}"
        # Prevent file path traversal outside of $pacstrap_dir
        [[ ! -f "${pacstrap_dir}${filename}" ]] && continue
        if [[ "$(realpath -q -- "${pacstrap_dir}${filename}")" != "${pacstrap_dir}"* ]]; then
            _msg_error "Failed to set permissions on '${pacstrap_dir}${filename}'. Outside of valid path." 1
        # Warn if the file does not exist
        elif [[ ! -e "${pacstrap_dir}${filename}" ]]; then
            _msg_warning "Cannot change permissions of '${pacstrap_dir}${filename}'. The file or directory does not exist."
        else
            if [[ "${filename: -1}" == "/" ]]; then
                chown -fhR -- "${permissions[0]}:${permissions[1]}" "${pacstrap_dir}${filename}"
                chmod -fR -- "${permissions[2]}" "${pacstrap_dir}${filename}"
            else
                chown -fh -- "${permissions[0]}:${permissions[1]}" "${pacstrap_dir}${filename}"
                chmod -f -- "${permissions[2]}" "${pacstrap_dir}${filename}"
            fi
        fi
    done
    _msg_info "Done!"
}

# Install desired packages to the root file system
_make_packages() {
    #_msg_debug "pkglist.sh ${pkglist_args[*]}" #pkglist.shを実行するタイミングで表示
    _msg_info "Installing packages to '${pacstrap_dir}/'..."

    if [[ -n "${gpg_key}" ]]; then
        exec {ARCHISO_GNUPG_FD}<>"${work_dir}/pubkey.gpg"
        export ARCHISO_GNUPG_FD
    fi

    # Package check
    #if [[ "${legacy_mode}" = true ]]; then
    #    readarray -t _pkglist < <("${tools_dir}/pkglist.sh" "${pkglist_args[@]}")
    #    readarray -t repopkgs < <(pacman-conf -c "${pacman_conf}" -l | xargs -I{} pacman -Sql --config "${pacman_conf}" --color=never {} && pacman -Sg)
    #    local _pkg
    #    for _pkg in "${_pkglist[@]}"; do
    #        _msg_info "Checking ${_pkg}..."
    #        if printf "%s\n" "${repopkgs[@]}" | grep -qx "${_pkg}"; then
    #            _pkglist_install+=("${_pkg}")
    #        else
    #            _msg_info "${_pkg} was not found. Install it with yay from AUR"
    #            norepopkg+=("${_pkg}")
    #        fi
    #    done
    #fi

    # Unset TMPDIR to work around https://bugs.archlinux.org/task/70580
    if [[ "${quiet}" = "y" ]]; then
        env -u TMPDIR pacstrap -C "${build_dir}/${buildmode}.pacman.conf" -c -G -M -- "${pacstrap_dir}" "${buildmode_pkg_list[@]}" &> /dev/null
    else
        env -u TMPDIR pacstrap -C "${build_dir}/${buildmode}.pacman.conf" -c -G -M -- "${pacstrap_dir}" "${buildmode_pkg_list[@]}"
    fi

    if [[ -n "${gpg_key}" ]]; then
        exec {ARCHISO_GNUPG_FD}<&-
        unset ARCHISO_GNUPG_FD
    fi

    # Create a list of packages to be finally installed as packages.list directly under the working directory.
    echo -e "# The list of packages that is installed in live cd.\n#\n" > "${build_dir}/packages.list"
    printf "%s\n" "${buildmode_pkg_list[@]}" >> "${build_dir}/packages.list"

    _msg_info "Done! Packages installed successfully."
}

_make_aur() {
    readarray -t _pkglist_aur < <("${tools_dir}/pkglist.sh" --aur "${pkglist_args[@]}")
    _pkglist_aur=("${_pkglist_aur[@]}" "${norepopkg[@]}")

    # Create a list of packages to be finally installed as packages.list directly under the working directory.
    echo -e "\n# AUR packages.\n#\n" >> "${build_dir}/packages.list"
    printf "%s\n" "${_pkglist_aur[@]}" >> "${build_dir}/packages.list"

    # prepare for yay
    cp -rf --preserve=mode "${script_path}/system/aur.sh" "${pacstrap_dir}/root/aur.sh"

    # Unset TMPDIR to work around https://bugs.archlinux.org/task/70580
    # --asdepsをつけているのでaur.shで削除される --neededをつけているので明示的にインストールされている場合削除されない
    if [[ "${quiet}" = "y" ]]; then
        env -u TMPDIR pacstrap -C "${build_dir}/${buildmode}.pacman.conf" -c -G -M -- "${pacstrap_dir}" --asdeps --needed "go" &> /dev/null
    else
        env -u TMPDIR pacstrap -C "${build_dir}/${buildmode}.pacman.conf" -c -G -M -- "${pacstrap_dir}" --asdeps --needed "go"
    fi

    # Run aur script
    _run_with_pacmanconf _chroot_run "bash" "/root/aur.sh" "${makepkg_script_args[@]}" "${_pkglist_aur[@]}"

    # Remove script
    remove "${pacstrap_dir}/root/aur.sh"

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
        cp -r "${_dir}" "${pacstrap_dir}/pkgbuilds/"
    done
    
    # copy buold script
    cp -rf --preserve=mode "${script_path}/system/pkgbuild.sh" "${pacstrap_dir}/root/pkgbuild.sh"

    # Run build script
    _run_with_pacmanconf _chroot_run "bash" "/root/pkgbuild.sh" "${makepkg_script_args[@]}" "/pkgbuilds"

    # Remove script
    remove "${pacstrap_dir}/root/pkgbuild.sh"

    return 0
}

# Customize installation.
_make_customize_airootfs() {
    local passwd=()

    #if [[ -e "${profile}/airootfs/etc/passwd" ]]; then
    #    _msg_info "Copying /etc/skel/* to user homes..."
    #    while IFS=':' read -a passwd -r; do
    #       # Only operate on UIDs in range 1000–59999
    #        (( passwd[2] >= 1000 && passwd[2] < 60000 )) || continue
    #        # Skip invalid home directories
    #        [[ "${passwd[5]}" == '/' ]] && continue
    #        [[ -z "${passwd[5]}" ]] && continue
    #        # Prevent path traversal outside of $pacstrap_dir
    #        if [[ "$(realpath -q -- "${pacstrap_dir}${passwd[5]}")" == "${pacstrap_dir}"* ]]; then
    #            if [[ ! -d "${pacstrap_dir}${passwd[5]}" ]]; then
    #                install -d -m 0750 -o "${passwd[2]}" -g "${passwd[3]}" -- "${pacstrap_dir}${passwd[5]}"
    #            fi
    #            cp -dnRT --preserve=mode,timestamps,links -- "${pacstrap_dir}/etc/skel/." "${pacstrap_dir}${passwd[5]}"
    #            chmod -f 0750 -- "${pacstrap_dir}${passwd[5]}"
    #            chown -hR -- "${passwd[2]}:${passwd[3]}" "${pacstrap_dir}${passwd[5]}"
    #        else
    #            _msg_error "Failed to set permissions on '${pacstrap_dir}${passwd[5]}'. Outside of valid path." 1
    #        fi
    #    done < "${profile}/airootfs/etc/passwd"
    #    _msg_info "Done!"
    #fi


    # customize_airootfs options
    # -b                        : Enable boot splash.
    # -d                        : Enable debug mode.
    # -g <locale_gen_name>      : Set locale-gen.
    # -i <inst_dir>             : Set install dir
    # -k <kernel config line>   : Set kernel name.
    # -o <os name>              : Set os name.
    # -p <password>             : Set password.
    # -s <shell>                : Set user shell.
    # -t                        : Set plymouth theme.
    # -u <username>             : Set live user name.
    # -x                        : Enable bash debug mode.
    # -z <locale_time>          : Set the time zone.
    # -l <locale_name>          : Set language.
    #
    # -j is obsolete in AlterISO3 and cannot be used.
    # -r is obsolete due to the removal of rebuild.
    # -k changed in AlterISO3 from passing kernel name to passing kernel configuration.

    # Generate options of customize_airootfs.sh.
    _airootfs_script_options=(-p "${password}" -k "${kernel} ${kernel_filename} ${kernel_mkinitcpio_profile}" -u "${username}" -o "${os_name}" -i "${install_dir}" -s "${usershell}" -a "${arch}" -g "${locale_gen_name}" -l "${locale_name}" -z "${locale_time}" -t "${theme_name}")
    [[ "${boot_splash}" = true ]] && _airootfs_script_options+=("-b")
    [[ "${debug}" = true       ]] && _airootfs_script_options+=("-d")
    [[ "${bash_debug}" = true  ]] && _airootfs_script_options+=("-x")

    _main_script="root/customize_airootfs.sh"

    _script_list=(
        "${pacstrap_dir}/root/customize_airootfs_${channel_name}.sh"
        "${pacstrap_dir}/root/customize_airootfs_${channel_name%.add}.sh"
    )

    for_module '_script_list+=("${pacstrap_dir}/root/customize_airootfs_{}.sh")'

    # Create script
    for _script in "${_script_list[@]}"; do
        if [[ -f "${_script}" ]]; then
            (echo -e "\n#--$(basename "${_script}")--#\n" && cat "${_script}")  >> "${pacstrap_dir}/${_main_script}"
            remove "${_script}"
        else
            _msg_debug "${_script} was not found."
        fi
    done

    _msg_info "Running ${_main_script} in '${pacstrap_dir}' chroot..."
    chmod 755 "${pacstrap_dir}/${_main_script}"
    chmod -f -- +x "${pacstrap_dir}/${_main_script}"
    cp "${pacstrap_dir}/${_main_script}" "${build_dir}/$(basename "${_main_script}")"
    # Unset TMPDIR to work around https://bugs.archlinux.org/task/70580
    env -u TMPDIR arch-chroot "${pacstrap_dir}" "/${_main_script}" "${_airootfs_script_options[@]}"
    rm -- "${pacstrap_dir}/root/customize_airootfs.sh"
    _msg_info "Done! customize_airootfs.sh run successfully."
}

# Copy mkinitcpio archiso hooks and build initramfs (airootfs)
_make_setup_mkinitcpio() {
    local _hook
    mkdir -p "${pacstrap_dir}/etc/initcpio/hooks" "${pacstrap_dir}/etc/initcpio/install"

    for _hook in "archiso" "archiso_shutdown" "archiso_pxe_common" "archiso_pxe_nbd" "archiso_pxe_http" "archiso_pxe_nfs" "archiso_loop_mnt"; do
        cp "${script_path}/system/initcpio/hooks/${_hook}" "${pacstrap_dir}/etc/initcpio/hooks"
        cp "${script_path}/system/initcpio/install/${_hook}" "${pacstrap_dir}/etc/initcpio/install"
    done

    sed -i "s|%COWSPACE%|${cowspace}|g" "${pacstrap_dir}/etc/initcpio/hooks/archiso"
    sed -i "s|/usr/lib/initcpio/|/etc/initcpio/|g" "${pacstrap_dir}/etc/initcpio/install/archiso_shutdown"
    cp "${script_path}/system/initcpio/install/archiso_kms" "${pacstrap_dir}/etc/initcpio/install"
    cp "${script_path}/system/initcpio/script/archiso_shutdown" "${pacstrap_dir}/etc/initcpio"
    cp "${script_path}/mkinitcpio/mkinitcpio-archiso.conf" "${pacstrap_dir}/etc/mkinitcpio-archiso.conf"
    [[ "${boot_splash}" = true ]] && cp "${script_path}/mkinitcpio/mkinitcpio-archiso-plymouth.conf" "${pacstrap_dir}/etc/mkinitcpio-archiso.conf"

    if [[ "${gpg_key}" ]]; then
      gpg --export "${gpg_key}" >"${build_dir}/gpgkey"
      exec 17<>"${build_dir}/gpgkey"
    fi

    _chroot_run mkinitcpio -c "/etc/mkinitcpio-archiso.conf" -k "/boot/${kernel_filename}" -g "/boot/archiso.img"

    [[ "${gpg_key}" ]] && exec 17<&-
    
    return 0
}

# Set up boot loaders
_make_bootmodes() {
    local bootmode
    for bootmode in "${bootmodes[@]}"; do
        _run_once "_make_bootmode_${bootmode}"
    done
}

# Copy kernel and initramfs to ISO 9660
_make_boot_on_iso9660() {
    local ucode_image
    _msg_info "Preparing kernel and initramfs for the ISO 9660 file system..."
    install -d -m 0755 -- "${isofs_dir}/${install_dir}/boot/${arch}"
    #install -m 0644 -- "${pacstrap_dir}/boot/initramfs-"*".img" "${isofs_dir}/${install_dir}/boot/${arch}/"
    install -m 0644 -- "${pacstrap_dir}/boot/archiso.img" "${isofs_dir}/${install_dir}/boot/${arch}/"
    install -m 0644 -- "${pacstrap_dir}/boot/vmlinuz-"* "${isofs_dir}/${install_dir}/boot/${arch}/"

    for ucode_image in "${ucodes[@]}"; do
        if [[ -e "${pacstrap_dir}/boot/${ucode_image}" ]]; then
        _msg_info "Installimg ${ucode_image} ..."
            install -m 0644 -- "${pacstrap_dir}/boot/${ucode_image}" "${isofs_dir}/${install_dir}/boot/"
            if [[ -e "${pacstrap_dir}/usr/share/licenses/${ucode_image%.*}/" ]]; then
                install -d -m 0755 -- "${isofs_dir}/${install_dir}/boot/licenses/${ucode_image%.*}/"
                install -m 0644 -- "${pacstrap_dir}/usr/share/licenses/${ucode_image%.*}/"* \
                    "${isofs_dir}/${install_dir}/boot/licenses/${ucode_image%.*}/"
            fi
        fi
    done
    _msg_info "Done!"
}

# Prepare syslinux for booting from MBR (isohybrid)
_make_bootmode_bios.syslinux.mbr() {
    _msg_info "Setting up SYSLINUX for BIOS booting from a disk..."

    # 一時ディレクトリに設定ファイルをコピー
    mkdir -p "${build_dir}/syslinux/"
    cp -a "${script_path}/syslinux/"* "${build_dir}/syslinux/"
    [[ -d "${channel_dir}/syslinux" ]] && [[ "${customized_syslinux}" = true ]] && cp -af "${channel_dir}/syslinux"* "${build_dir}/syslinux/"

    install -d -m 0755 -- "${isofs_dir}/syslinux"
    for _cfg in "${build_dir}/syslinux/"*.cfg; do
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
             s|%OS_NAME%|${os_name}|g;
             s|%KERNEL_FILENAME%|${kernel_filename}|g;
             s|%INSTALL_DIR%|${install_dir}|g;
             s|%ARCH%|${arch}|g" \
             "${_cfg}" > "${isofs_dir}/syslinux/${_cfg##*/}"
    done

    # Replace the SYSLINUX configuration file with or without boot splash.
    local _pxe_or_sys _remove_config
    for _pxe_or_sys in "sys" "pxe"; do
        remove "${isofs_dir}/syslinux/archiso_${_pxe_or_sys}_${not_use_bootloader_type}.cfg"
        mv "${isofs_dir}/syslinux/archiso_${_pxe_or_sys}_${use_bootloader_type}.cfg" "${isofs_dir}/syslinux/archiso_${_pxe_or_sys}-linux.cfg"
    done

    # remove config
    function _remove_config() {
        remove "${isofs_dir}/syslinux/${1}"
        sed -i "|$(grep "${1}" "${isofs_dir}/syslinux/archiso_sys.cfg")|d" "${isofs_dir}/syslinux/archiso_sys.cfg" 
    }

    [[ "${norescue_entry}" = true  ]] && _remove_config archiso_sys_rescue.cfg
    [[ "${memtest86}"      = false ]] && _remove_config memtest86.cfg
    
    if [[ -e "${channel_dir}/splash.png" ]]; then
        install -m 0644 -- "${channel_dir}/splash.png" "${isofs_dir}/syslinux/"
    else
        install -m 0644 -- "${script_path}/syslinux/splash.png" "${isofs_dir}/syslinux"
    fi
    install -m 0644 -- "${pacstrap_dir}/usr/lib/syslinux/bios/"*.c32 "${isofs_dir}/syslinux/"
    install -m 0644 -- "${pacstrap_dir}/usr/lib/syslinux/bios/lpxelinux.0" "${isofs_dir}/syslinux/"
    install -m 0644 -- "${pacstrap_dir}/usr/lib/syslinux/bios/memdisk" "${isofs_dir}/syslinux/"

    _run_once _make_boot_on_iso9660

    if [[ -e "${isofs_dir}/syslinux/hdt.c32" ]]; then
        install -d -m 0755 -- "${isofs_dir}/syslinux/hdt"
        if [[ -e "${pacstrap_dir}/usr/share/hwdata/pci.ids" ]]; then
            gzip -cn9 "${pacstrap_dir}/usr/share/hwdata/pci.ids" > \
                "${isofs_dir}/syslinux/hdt/pciids.gz"
        fi
        find "${pacstrap_dir}/usr/lib/modules" -name 'modules.alias' -print -exec gzip -cn9 '{}' ';' -quit > \
            "${isofs_dir}/syslinux/hdt/modalias.gz"
    fi

    # Add other aditional/extra files to ${install_dir}/boot/
    if [[ -e "${pacstrap_dir}/boot/memtest86+/memtest.bin" ]]; then
        # rename for PXE: https://wiki.archlinux.org/title/Syslinux#Using_memtest
        install -m 0644 -- "${pacstrap_dir}/boot/memtest86+/memtest.bin" "${isofs_dir}/${install_dir}/boot/memtest"
        install -d -m 0755 -- "${isofs_dir}/${install_dir}/boot/licenses/memtest86+/"
        install -m 0644 -- "${pacstrap_dir}/usr/share/licenses/common/GPL2/license.txt" \
            "${isofs_dir}/${install_dir}/boot/licenses/memtest86+/"
    fi
    _msg_info "Done! SYSLINUX set up for BIOS booting from a disk successfully."
}

# Prepare syslinux for El-Torito booting
_make_bootmode_bios.syslinux.eltorito() {
    _msg_info "Setting up SYSLINUX for BIOS booting from an optical disc..."
    install -d -m 0755 -- "${isofs_dir}/syslinux"
    install -m 0644 -- "${pacstrap_dir}/usr/lib/syslinux/bios/isolinux.bin" "${isofs_dir}/syslinux/"
    install -m 0644 -- "${pacstrap_dir}/usr/lib/syslinux/bios/isohdpfx.bin" "${isofs_dir}/syslinux/"

    # ISOLINUX and SYSLINUX installation is shared
    _run_once _make_bootmode_bios.syslinux.mbr

    _msg_info "Done! SYSLINUX set up for BIOS booting from an optical disc successfully."
}

# Copy kernel and initramfs to FAT image
_make_boot_on_fat() {
    local ucode_image all_ucode_images=()
    _msg_info "Preparing kernel and initramfs for the FAT file system..."
    mmd -i "${work_dir}/efiboot.img" \
        "::/${install_dir}" "::/${install_dir}/boot" "::/${install_dir}/boot/${arch}"
    mcopy -i "${work_dir}/efiboot.img" "${pacstrap_dir}/boot/vmlinuz-"* \
        "${pacstrap_dir}/boot/initramfs-"*".img" "::/${install_dir}/boot/${arch}/"
    for ucode_image in "${ucodes[@]}"; do
        if [[ -e "${pacstrap_dir}/boot/${ucode_image}" ]]; then
            all_ucode_images+=("${pacstrap_dir}/boot/${ucode_image}")
        fi
    done
    if (( ${#all_ucode_images[@]} )); then
        mcopy -i "${work_dir}/efiboot.img" "${all_ucode_images[@]}" "::/${install_dir}/boot/"
    fi
    _msg_info "Done!"
}

# Create a FAT image (efiboot.img) which will serve as the EFI system partition
# $1: image size in bytes
_make_efibootimg() {
    local imgsize="0"

    # Convert from bytes to KiB and round up to the next full MiB with an additional MiB for reserved sectors.
    imgsize="$(awk 'function ceil(x){return int(x)+(x>int(x))}
            function byte_to_kib(x){return x/1024}
            function mib_to_kib(x){return x*1024}
            END {print mib_to_kib(ceil((byte_to_kib($1)+1024)/1024))}' <<< "${1}"
    )"
    # The FAT image must be created with mkfs.fat not mformat, as some systems have issues with mformat made images:
    # https://lists.gnu.org/archive/html/grub-devel/2019-04/msg00099.html
    rm -f -- "${work_dir}/efiboot.img"
    _msg_info "Creating FAT image of size: ${imgsize} KiB..."
    mkfs.fat -C -n ARCHISO_EFI "${work_dir}/efiboot.img" "${imgsize}"

    # Create the default/fallback boot path in which a boot loaders will be placed later.
    mmd -i "${work_dir}/efiboot.img" ::/EFI ::/EFI/BOOT
}

# Prepare system-boot for booting when written to a disk (isohybrid)
_make_bootmode_uefi-x64.systemd-boot.esp() {
    local _file efiboot_imgsize
    local _available_ucodes=()
    _msg_info "Setting up systemd-boot for UEFI booting..."

    for _file in "${ucodes[@]}"; do
        if [[ -e "${pacstrap_dir}/boot/${_file}" ]]; then
            _available_ucodes+=("${pacstrap_dir}/boot/${_file}")
        fi
    done
    # Calculate the required FAT image size in bytes
    efiboot_imgsize="$(du -bc \
        "${pacstrap_dir}/usr/lib/systemd/boot/efi/systemd-bootx64.efi" \
        "${pacstrap_dir}/usr/share/edk2-shell/x64/Shell_Full.efi" \
        "${script_path}/efiboot/${use_bootloader_type}" \
        "${pacstrap_dir}/boot/vmlinuz-"* \
        "${pacstrap_dir}/boot/initramfs-"*".img" \
        "${_available_ucodes[@]}" \
        2>/dev/null | awk 'END { print $1 }')"
    # Create a FAT image for the EFI system partition
    _make_efibootimg "${efiboot_imgsize}"

    # Copy systemd-boot EFI binary to the default/fallback boot path
    mcopy -i "${work_dir}/efiboot.img" \
        "${pacstrap_dir}/usr/lib/systemd/boot/efi/systemd-bootx64.efi" ::/EFI/BOOT/BOOTx64.EFI

    # Copy systemd-boot configuration files
    mmd -i "${work_dir}/efiboot.img" ::/loader ::/loader/entries
    mcopy -i "${work_dir}/efiboot.img" "${script_path}/efiboot/${use_bootloader_type}/loader.conf" ::/loader/
    for _conf in "${script_path}/efiboot/${use_bootloader_type}/entries/"*".conf"; do
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
             s|%INSTALL_DIR%|${install_dir}|g;
             s|%OS_NAME%|${os_name}|g;
             s|%KERNEL_FILENAME%|${kernel_filename}|g;
             s|%ARCH%|${arch}|g" \
            "${_conf}" | mcopy -i "${work_dir}/efiboot.img" - "::/loader/entries/${_conf##*/}"
    done

    # shellx64.efi is picked up automatically when on /
    if [[ -e "${pacstrap_dir}/usr/share/edk2-shell/x64/Shell_Full.efi" ]]; then
        mcopy -i "${work_dir}/efiboot.img" \
            "${pacstrap_dir}/usr/share/edk2-shell/x64/Shell_Full.efi" ::/shellx64.efi
    fi

    # Copy kernel and initramfs to FAT image.
    # systemd-boot can only access files from the EFI system partition it was launched from.
    _make_boot_on_fat

    _msg_info "Done! systemd-boot set up for UEFI booting successfully."
}

# Prepare system-boot for El Torito booting
_make_bootmode_uefi-x64.systemd-boot.eltorito() {
    # El Torito UEFI boot requires an image containing the EFI system partition.
    # uefi-x64.systemd-boot.eltorito has the same requirements as uefi-x64.systemd-boot.esp
    _run_once _make_bootmode_uefi-x64.systemd-boot.esp

    # Additionally set up system-boot in ISO 9660. This allows creating a medium for the live environment by using
    # manual partitioning and simply copying the ISO 9660 file system contents.
    # This is not related to El Torito booting and no firmware uses these files.
    _msg_info "Preparing an /EFI directory for the ISO 9660 file system..."
    install -d -m 0755 -- "${isofs_dir}/EFI/BOOT"

    # Copy systemd-boot EFI binary to the default/fallback boot path
    install -m 0644 -- "${pacstrap_dir}/usr/lib/systemd/boot/efi/systemd-bootx64.efi" \
        "${isofs_dir}/EFI/BOOT/BOOTx64.EFI"

    # Copy systemd-boot configuration files
    install -d -m 0755 -- "${isofs_dir}/loader/entries"
    install -m 0644 -- "${script_path}/efiboot/${use_bootloader_type}/loader.conf" "${isofs_dir}/loader/"
    for _conf in "${script_path}/efiboot/${use_bootloader_type}/entries/"*".conf"; do
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
             s|%INSTALL_DIR%|${install_dir}|g;
             s|%OS_NAME%|${os_name}|g;
             s|%KERNEL_FILENAME%|${kernel_filename}|g;
             s|%ARCH%|${arch}|g" \
            "${_conf}" > "${isofs_dir}/loader/entries/${_conf##*/}"
    done

    # edk2-shell based UEFI shell
    # shellx64.efi is picked up automatically when on /
    if [[ -e "${pacstrap_dir}/usr/share/edk2-shell/x64/Shell_Full.efi" ]]; then
        install -m 0644 -- "${pacstrap_dir}/usr/share/edk2-shell/x64/Shell_Full.efi" "${isofs_dir}/shellx64.efi"
    fi

    _msg_info "Done!"
}

_validate_requirements_bootmode_bios.syslinux.mbr() {
    # bios.syslinux.mbr requires bios.syslinux.eltorito
    # shellcheck disable=SC2076
    if [[ ! " ${bootmodes[*]} " =~ ' bios.syslinux.eltorito ' ]]; then
        (( validation_error=validation_error+1 ))
        _msg_error "Using 'bios.syslinux.mbr' boot mode without 'bios.syslinux.eltorito' is not supported." 0
    fi

    # Check if the syslinux package is in the package list
    # shellcheck disable=SC2076
    if [[ ! " ${pkg_list[*]} " =~ ' syslinux ' ]]; then
        (( validation_error=validation_error+1 ))
        _msg_error "Validating '${bootmode}': The 'syslinux' package is missing from the package list!" 0
    fi

    # Check if syslinux configuration files exist
    if [[ ! -d "${script_path}/syslinux" ]]; then
        (( validation_error=validation_error+1 ))
        _msg_error "Validating '${bootmode}': The '${script_path}/syslinux' directory is missing!" 0
    else
        local cfgfile
        for cfgfile in "${script_path}/syslinux/"*'.cfg'; do
            if [[ -e "${cfgfile}" ]]; then
                break
            else
                (( validation_error=validation_error+1 ))
                _msg_error "Validating '${bootmode}': No configuration file found in '${script_path}/syslinux'!" 0
            fi
        done
    fi

    # Check for optional packages
    # shellcheck disable=SC2076
    if [[ ! " ${pkg_list[*]} " =~ ' memtest86+ ' ]]; then
        _msg_info "Validating '${bootmode}': 'memtest86+' is not in the package list. Memmory testing will not be available from syslinux."
    fi
}

_validate_requirements_bootmode_bios.syslinux.eltorito() {
    # bios.syslinux.eltorito has the exact same requirements as bios.syslinux.mbr
    _validate_requirements_bootmode_bios.syslinux.mbr
}

_validate_requirements_bootmode_uefi-x64.systemd-boot.esp() {
    # Check if mkfs.fat is available
    if ! command -v mkfs.fat &> /dev/null; then
        (( validation_error=validation_error+1 ))
        _msg_error "Validating '${bootmode}': mkfs.fat is not available on this host. Install 'dosfstools'!" 0
    fi

    # Check if mmd and mcopy are available
    if ! { command -v mmd &> /dev/null && command -v mcopy &> /dev/null; }; then
        _msg_error "Validating '${bootmode}': mmd and/or mcopy are not available on this host. Install 'mtools'!" 0
    fi

    # Check if systemd-boot configuration files exist
    if [[ ! -d "${script_path}/efiboot/${use_bootloader_type}/entries" ]]; then
        (( validation_error=validation_error+1 ))
        _msg_error "Validating '${bootmode}': The '${script_path}/efiboot/${use_bootloader_type}/entries' directory is missing!" 0
    else
        if [[ ! -e "${script_path}/efiboot/${use_bootloader_type}/loader.conf" ]]; then
            (( validation_error=validation_error+1 ))
            _msg_error "Validating '${bootmode}': File '${script_path}/efiboot/${use_bootloader_type}/loader.conf' not found!" 0
        fi
        local conffile
        for conffile in "${script_path}/efiboot/${use_bootloader_type}/entries/"*'.conf'; do
            if [[ -e "${conffile}" ]]; then
                break
            else
                (( validation_error=validation_error+1 ))
                _msg_error "Validating '${bootmode}': No configuration file found in '${script_path}/efiboot/${use_bootloader_type}/entries/'!" 0
            fi
        done
    fi

    # Check for optional packages
    # shellcheck disable=SC2076
    if [[ ! " ${pkg_list[*]} " =~ ' edk2-shell ' ]]; then
        _msg_info "'edk2-shell' is not in the package list. The ISO will not contain a bootable UEFI shell."
    fi
}

_validate_requirements_bootmode_uefi-x64.systemd-boot.eltorito() {
    # uefi-x64.systemd-boot.eltorito has the exact same requirements as uefi-x64.systemd-boot.esp
    _validate_requirements_bootmode_uefi-x64.systemd-boot.esp
}

# Build airootfs filesystem image
_prepare_airootfs_image() {
    _run_once "_mkairootfs_${airootfs_image_type}"
    _mkchecksum
    if [[ -n "${gpg_key}" ]]; then
        _mksignature
    fi
}

# export build artifacts for netboot
_export_netboot_artifacts() {
    _msg_info "Exporting netboot artifacts..."
    install -d -m 0755 "${out_dir}"
    cp -a -- "${isofs_dir}/${install_dir}/" "${out_dir}/"
    _msg_info "Done!"
    du -h -- "${out_dir}/${install_dir}"
}

# sign build artifacts for netboot
_sign_netboot_artifacts() {
    local _file _dir
    local _files_to_sign=()
    _msg_info "Signing netboot artifacts..."
    _dir="${isofs_dir}/${install_dir}/boot/"
    for _file in "${ucodes[@]}"; do
        if [[ -e "${_dir}${_file}" ]]; then
            _files_to_sign+=("${_dir}${_file}")
        fi
    done
    for _file in "${_files_to_sign[@]}" "${_dir}${arch}/vmlinuz-"* "${_dir}${arch}/initramfs-"*.img; do
        openssl cms \
            -sign \
            -binary \
            -noattr \
            -in "${_file}" \
            -signer "${cert_list[0]}" \
            -inkey "${cert_list[1]}" \
            -outform DER \
            -out "${_file}".ipxe.sig
    done
    _msg_info "Done!"
}

_validate_requirements_airootfs_image_type_squashfs() {
    if ! command -v mksquashfs &> /dev/null; then
        (( validation_error=validation_error+1 ))
        _msg_error "Validating '${airootfs_image_type}': mksquashfs is not available on this host. Install 'squashfs-tools'!" 0
    fi
}

_validate_requirements_airootfs_image_type_ext4+squashfs() {
    if ! { command -v mkfs.ext4 &> /dev/null && command -v tune2fs &> /dev/null; }; then
        (( validation_error=validation_error+1 ))
        _msg_error "Validating '${airootfs_image_type}': mkfs.ext4 and/or tune2fs is not available on this host. Install 'e2fsprogs'!" 0
    fi
    _validate_requirements_airootfs_image_type_squashfs
}

_validate_requirements_airootfs_image_type_erofs() {
    if ! command -v mkfs.erofs; then
        (( validation_error=validation_error+1 ))
        _msg_error "Validating '${airootfs_image_type}': mkfs.erofs is not available on this host. Install 'erofs-utils'!" 0
    fi
}

_validate_common_requirements_buildmode_all() {
    if ! command -v pacman &> /dev/null; then
        (( validation_error=validation_error+1 ))
        _msg_error "Validating build mode '${_buildmode}': pacman is not available on this host. Install 'pacman'!" 0
    fi
    if ! command -v find &> /dev/null; then
        (( validation_error=validation_error+1 ))
        _msg_error "Validating build mode '${_buildmode}': find is not available on this host. Install 'findutils'!" 0
    fi
    if ! command -v gzip &> /dev/null; then
        (( validation_error=validation_error+1 ))
        _msg_error "Validating build mode '${_buildmode}': gzip is not available on this host. Install 'gzip'!" 0
    fi
}

_validate_requirements_buildmode_bootstrap() {
    local bootstrap_pkg_list_from_file=()

    # Check if packages for the bootstrap image are specified
    if [[ -e "${bootstrap_packages}" ]]; then
        mapfile -t bootstrap_pkg_list_from_file < <("${tools_dir}/pkglist.sh" "${pkglist_args[@]}")
        bootstrap_pkg_list+=("${bootstrap_pkg_list_from_file[@]}")
        if (( ${#bootstrap_pkg_list_from_file[@]} < 1 )); then
            (( validation_error=validation_error+1 ))
            _msg_error "No package specified in '${bootstrap_packages}'." 0
        fi
    else
        (( validation_error=validation_error+1 ))
        _msg_error "Bootstrap packages file '${bootstrap_packages}' does not exist." 0
    fi

    _validate_common_requirements_buildmode_all
    if ! command -v bsdtar &> /dev/null; then
        (( validation_error=validation_error+1 ))
        _msg_error "Validating build mode '${_buildmode}': bsdtar is not available on this host. Install 'libarchive'!" 0
    fi
}

_validate_common_requirements_buildmode_iso_netboot() {
    local bootmode
    local pkg_list_from_file=()

    # Check if the package list file exists and read packages from it
    _msg_debug "pkglist.sh ${pkglist_args[*]}"
    mapfile -t pkg_list_from_file < <("${tools_dir}/pkglist.sh" "${pkglist_args[@]}")
    pkg_list+=("${pkg_list_from_file[@]}")
    if (( ${#pkg_list_from_file[@]} < 1 )); then
        (( validation_error=validation_error+1 ))
        _msg_error "No package specified in '${packages}'." 0
    fi

    # Check if the specified bootmodes are supported
    if (( ${#bootmodes[@]} < 1 )); then
        (( validation_error=validation_error+1 ))
        _msg_error "No boot modes specified'." 0
    fi
    for bootmode in "${bootmodes[@]}"; do
        if typeset -f "_make_bootmode_${bootmode}" &> /dev/null; then
            if typeset -f "_validate_requirements_bootmode_${bootmode}" &> /dev/null; then
                "_validate_requirements_bootmode_${bootmode}"
            else
                _msg_warning "Function '_validate_requirements_bootmode_${bootmode}' does not exist. Validating the requirements of '${bootmode}' boot mode will not be possible."
            fi
        else
            (( validation_error=validation_error+1 ))
            _msg_error "${bootmode} is not a valid boot mode!" 0
        fi
    done

    # Check if the specified airootfs_image_type is supported
    if typeset -f "_mkairootfs_${airootfs_image_type}" &> /dev/null; then
        if typeset -f "_validate_requirements_airootfs_image_type_${airootfs_image_type}" &> /dev/null; then
            "_validate_requirements_airootfs_image_type_${airootfs_image_type}"
        else
            _msg_warning "Function '_validate_requirements_airootfs_image_type_${airootfs_image_type}' does not exist. Validating the requirements of '${airootfs_image_type}' airootfs image type will not be possible."
        fi
    else
        (( validation_error=validation_error+1 ))
        _msg_error "Unsupported image type: '${airootfs_image_type}'" 0
    fi
}

_validate_requirements_buildmode_iso() {
    _validate_common_requirements_buildmode_iso_netboot
    _validate_common_requirements_buildmode_all
    if ! command -v awk &> /dev/null; then
        (( validation_error=validation_error+1 ))
        _msg_error "Validating build mode '${_buildmode}': awk is not available on this host. Install 'awk'!" 0
    fi
}

_validate_requirements_buildmode_netboot() {
    local _override_cert_list=()

    if [[ "${sign_netboot_artifacts}" == "y" ]]; then
        # Check if the certificate files exist
        for _cert in "${cert_list[@]}"; do
            if [[ -e "${_cert}" ]]; then
                _override_cert_list+=("$(realpath -- "${_cert}")")
            else
                (( validation_error=validation_error+1 ))
                _msg_error "File '${_cert}' does not exist." 0
            fi
        done
        cert_list=("${_override_cert_list[@]}")
        # Check if there are at least two certificate files
        if (( ${#cert_list[@]} < 2 )); then
            (( validation_error=validation_error+1 ))
            _msg_error "Two certificates are required for codesigning, but '${cert_list[*]}' is provided." 0
        fi
    fi
    _validate_common_requirements_buildmode_iso_netboot
    _validate_common_requirements_buildmode_all
    if ! command -v openssl &> /dev/null; then
        (( validation_error=validation_error+1 ))
        _msg_error "Validating build mode '${_buildmode}': openssl is not available on this host. Install 'openssl'!" 0
    fi
}

# SYSLINUX El Torito
_add_xorrisofs_options_bios.syslinux.eltorito() {
    xorrisofs_options+=(
        # El Torito boot image for x86 BIOS
        '-eltorito-boot' 'syslinux/isolinux.bin'
        # El Torito boot catalog file
        '-eltorito-catalog' 'syslinux/boot.cat'
        # Required options to boot with ISOLINUX
        '-no-emul-boot' '-boot-load-size' '4' '-boot-info-table'
    )
}

# SYSLINUX MBR (isohybrid)
_add_xorrisofs_options_bios.syslinux.mbr() {
    xorrisofs_options+=(
        # SYSLINUX MBR bootstrap code; does not work without "-eltorito-boot syslinux/isolinux.bin"
        '-isohybrid-mbr' "${isofs_dir}/syslinux/isohdpfx.bin"
        # When GPT is used, create an additional partition in the MBR (besides 0xEE) for sectors 0–1 (MBR
        # bootstrap code area) and mark it as bootable
        # May allow booting on some systems
        # https://wiki.archlinux.org/title/Partitioning#Tricking_old_BIOS_into_booting_from_GPT
        '--mbr-force-bootable'
        # Move the first partition away from the start of the ISO to match the expectations of partition editors
        # May allow booting on some systems
        # https://dev.lovelyhq.com/libburnia/libisoburn/src/branch/master/doc/partition_offset.wiki
        '-partition_offset' '16'
    )
}

# systemd-boot in an attached EFI system partition
_add_xorrisofs_options_uefi-x64.systemd-boot.esp() {
    # Move the first partition away from the start of the ISO, otherwise the GPT will not be valid and ISO 9660
    # partition will not be mountable
    # shellcheck disable=SC2076
    [[ " ${xorrisofs_options[*]} " =~ ' -partition_offset ' ]] || xorrisofs_options+=('-partition_offset' '16')
    # Attach efiboot.img as a second partition and set its partition type to "EFI system partition"
    xorrisofs_options+=('-append_partition' '2' 'C12A7328-F81F-11D2-BA4B-00A0C93EC93B' "${work_dir}/efiboot.img")
    # Ensure GPT is used as some systems do not support UEFI booting without it
    # shellcheck disable=SC2076
    if [[ " ${bootmodes[*]} " =~ ' bios.syslinux.mbr ' ]]; then
        # A valid GPT prevents BIOS booting on some systems, instead use an invalid GPT (without a protective MBR).
        # The attached partition will have the EFI system partition type code in MBR, but in the invalid GPT it will
        # have a Microsoft basic partition type code.
        if [[ ! " ${bootmodes[*]} " =~ ' uefi-x64.systemd-boot.eltorito ' ]]; then
            # If '-isohybrid-gpt-basdat' is specified before '-e', then the appended EFI system partition will have the
            # EFI system partition type ID/GUID in both MBR and GPT. If '-isohybrid-gpt-basdat' is specified after '-e',
            # the appended EFI system partition will have the Microsoft basic data type GUID in GPT.
            if [[ ! " ${xorrisofs_options[*]} " =~ ' -isohybrid-gpt-basdat ' ]]; then
                xorrisofs_options+=('-isohybrid-gpt-basdat')
            fi
        fi
    else
        # Use valid GPT if BIOS booting support will not be required
        xorrisofs_options+=('-appended_part_as_gpt')
    fi
}

# systemd-boot via El Torito
_add_xorrisofs_options_uefi-x64.systemd-boot.eltorito() {
    # shellcheck disable=SC2076
    if [[ " ${bootmodes[*]} " =~ ' uefi-x64.systemd-boot.esp ' ]]; then
        # systemd-boot in an attached EFI system partition via El Torito
        xorrisofs_options+=(
            # Start a new El Torito boot entry for UEFI
            '-eltorito-alt-boot'
            # Set the second partition as the El Torito UEFI boot image
            '-e' '--interval:appended_partition_2:all::'
            # Boot image is not emulating floppy or hard disk; required for all known boot loaders
            '-no-emul-boot'
        )
        # A valid GPT prevents BIOS booting on some systems, use an invalid GPT instead.
        if [[ " ${bootmodes[*]} " =~ ' bios.syslinux.mbr ' ]]; then
            # If '-isohybrid-gpt-basdat' is specified before '-e', then the appended EFI system partition will have the
            # EFI system partition type ID/GUID in both MBR and GPT. If '-isohybrid-gpt-basdat' is specified after '-e',
            # the appended EFI system partition will have the Microsoft basic data type GUID in GPT.
            if [[ ! " ${xorrisofs_options[*]} " =~ ' -isohybrid-gpt-basdat ' ]]; then
                xorrisofs_options+=('-isohybrid-gpt-basdat')
            fi
        fi
    else
        # The ISO will not contain a GPT partition table, so to be able to reference efiboot.img, place it as a
        # file inside the ISO 9660 file system
        install -d -m 0755 -- "${isofs_dir}/EFI/archiso"
        cp -a -- "${work_dir}/efiboot.img" "${isofs_dir}/EFI/archiso/efiboot.img"
        # systemd-boot in an embedded efiboot.img via El Torito
        xorrisofs_options+=(
            # Start a new El Torito boot entry for UEFI
            '-eltorito-alt-boot'
            # Set efiboot.img as the El Torito UEFI boot image
            '-e' 'EFI/archiso/efiboot.img'
            # Boot image is not emulating floppy or hard disk; required for all known boot loaders
            '-no-emul-boot'
        )
    fi
    # Specify where to save the El Torito boot catalog file in case it is not already set by bios.syslinux.eltorito
    # shellcheck disable=SC2076
    [[ " ${bootmodes[*]} " =~ ' bios.' ]] || xorrisofs_options+=('-eltorito-catalog' 'EFI/boot.cat')
}

# Build bootstrap image
_build_bootstrap_image() {
    local _bootstrap_parent
    _bootstrap_parent="$(dirname -- "${pacstrap_dir}")"

    [[ -d "${out_dir}" ]] || install -d -- "${out_dir}"

    cd -- "${_bootstrap_parent}"

    _msg_info "Creating bootstrap image..."
    bsdtar -cf - "root.${arch}" | gzip -cn9 > "${out_dir}/${image_name}"
    _msg_info "Done!"
    du -h -- "${out_dir}/${image_name}"
    cd -- "${OLDPWD}"
}

# Build ISO
_build_iso_image() {
    local xorrisofs_options=()
    local bootmode

    [[ -d "${out_dir}" ]] || install -d -- "${out_dir}"

    [[ "${quiet}" == "y" ]] && xorrisofs_options+=('-quiet')

    # Add required xorrisofs options for each boot mode
    for bootmode in "${bootmodes[@]}"; do
        typeset -f "_add_xorrisofs_options_${bootmode}" &> /dev/null && "_add_xorrisofs_options_${bootmode}"
    done

    rm -f -- "${out_dir}/${image_name}"
    _msg_info "Creating ISO image..."
    xorriso -as mkisofs \
            -iso-level 3 \
            -full-iso9660-filenames \
            -joliet \
            -joliet-long \
            -rational-rock \
            -volid "${iso_label}" \
            -appid "${iso_application}" \
            -publisher "${iso_publisher}" \
            -preparer "prepared by ${app_name}" \
            "${xorrisofs_options[@]}" \
            -output "${out_dir}/${image_name}" \
            "${isofs_dir}/"
    _mkimagechecksum "${out_dir}/${iso_filename}"
    _msg_info "Done!"
    du -h -- "${out_dir}/${image_name}"
    _msg_info "The password for the live user and root is ${password}."
}

# Read profile's values from profiledef.sh
_read_profile() {
    if [[ -z "${profile}" ]]; then
        _msg_error "No profile specified!" 1
    fi
    if [[ ! -d "${profile}" ]]; then
        _msg_error "Profile '${profile}' does not exist!" 1
    elif [[ ! -e "${profile}/profiledef.sh" ]]; then
        _msg_error "Profile '${profile}' is missing 'profiledef.sh'!" 1
    else
        cd -- "${profile}"

        # Source profile's variables
        # shellcheck source=configs/releng/profiledef.sh
        . "${profile}/profiledef.sh"

        # Resolve paths of files that are expected to reside in the profile's directory
        [[ -n "$packages" ]] || packages="${profile}/packages.${arch}"
        packages="$(realpath -- "${packages}")"
        pacman_conf="$(realpath -- "${pacman_conf}")"

        # Resolve paths of files that may reside in the profile's directory
        if [[ -z "$bootstrap_packages" ]] && [[ -e "${profile}/bootstrap_packages.${arch}" ]]; then
            bootstrap_packages="${profile}/bootstrap_packages.${arch}"
            bootstrap_packages="$(realpath -- "${bootstrap_packages}")"
            pacman_conf="$(realpath -- "${pacman_conf}")"
        fi

        cd -- "${OLDPWD}"
    fi
}

# Validate set options
_validate_options() {
    local validation_error=0 _buildmode

    _msg_info "Validating options..."

    # Check if pacman configuration file exists
    if [[ ! -e "${pacman_conf}" ]]; then
        (( validation_error=validation_error+1 ))
        _msg_error "File '${pacman_conf}' does not exist." 0
    fi

    # Check if the specified buildmodes are supported
    for _buildmode in "${buildmodes[@]}"; do
        if typeset -f "_build_buildmode_${_buildmode}" &> /dev/null; then
            if typeset -f "_validate_requirements_buildmode_${_buildmode}" &> /dev/null; then
                "_validate_requirements_buildmode_${_buildmode}"
            else
                _msg_warning "Function '_validate_requirements_buildmode_${_buildmode}' does not exist. Validating the requirements of '${_buildmode}' build mode will not be possible."
            fi
        else
            (( validation_error=validation_error+1 ))
            _msg_error "${_buildmode} is not a valid build mode!" 0
        fi
    done

    if (( validation_error )); then
        _msg_error "${validation_error} errors were encountered while validating the profile. Aborting." 1
    fi
    _msg_info "Done!"
}


_export_gpg_publickey() {
    rm -f -- "${work_dir}/pubkey.gpg"
    gpg --batch --no-armor --output "${work_dir}/pubkey.gpg" --export "${gpg_key}"
}

_make_version() {
    local _os_release

    _msg_info "Creating version files..."
    # Write version file to system installation dir
    rm -f -- "${pacstrap_dir}/version"
    printf '%s\n' "${iso_version}" > "${pacstrap_dir}/version"

    if [[ "${buildmode}" == @("iso"|"netboot") ]]; then
        install -d -m 0755 -- "${isofs_dir}/${install_dir}"
        # Write version file to ISO 9660
        printf '%s\n' "${iso_version}" > "${isofs_dir}/${install_dir}/version"
        # Write grubenv with version information to ISO 9660
        printf '%.1024s' "$(printf '# GRUB Environment Block\nNAME=%s\nVERSION=%s\n%s' \
            "${iso_name}" "${iso_version}" "$(printf '%0.1s' "#"{1..1024})")" \
            > "${isofs_dir}/${install_dir}/grubenv"
    fi

    # Append IMAGE_ID & IMAGE_VERSION to os-release
    _os_release="$(realpath -- "${pacstrap_dir}/etc/os-release")"
    if [[ ! -e "${pacstrap_dir}/etc/os-release" && -e "${pacstrap_dir}/usr/lib/os-release" ]]; then
        _os_release="$(realpath -- "${pacstrap_dir}/usr/lib/os-release")"
    fi
    if [[ "${_os_release}" != "${pacstrap_dir}"* ]]; then
        _msg_warning "os-release file '${_os_release}' is outside of valid path."
    else
        [[ ! -e "${_os_release}" ]] || sed -i '/^IMAGE_ID=/d;/^IMAGE_VERSION=/d' "${_os_release}"
        printf 'IMAGE_ID=%s\nIMAGE_VERSION=%s\n' "${iso_name}" "${iso_version}" >> "${_os_release}"
    fi
    _msg_info "Done!"
}

_make_pkglist() {
    _msg_info "Creating a list of installed packages on live-enviroment..."
    case "${buildmode}" in
        "bootstrap")
            pacman -Q --sysroot "${pacstrap_dir}" > "${pacstrap_dir}/pkglist.${arch}.txt"
            ;;
        "iso"|"netboot")
            install -d -m 0755 -- "${isofs_dir}/${install_dir}"
            pacman -Q --sysroot "${pacstrap_dir}" > "${isofs_dir}/${install_dir}/pkglist.${arch}.txt"
            ;;
    esac
    _msg_info "Done!"
}

# build the base for an ISO and/or a netboot target
_build_iso_base() {
    local run_once_mode="base"
    #local buildmode_packages="${packages}"
    # Set the package list to use
    local buildmode_pkg_list=("${pkg_list[@]}")
    # Set up essential directory paths
    #pacstrap_dir="${work_dir}/${arch}/airootfs" 
    #isofs_dir="${work_dir}/iso"

    # pacstrap_dirをpacstrap_dirに変更
    # isofs_dirは別で定義
    pacstrap_dir="${pacstrap_dir}"

    # Create working directory
    #[[ -d "${work_dir}" ]] || install -d -- "${work_dir}"
    # Write build date to file or if the file exists, read it from there
    if [[ -e "${build_dir}/build_date" ]]; then
        SOURCE_DATE_EPOCH="$(<"${build_dir}/build_date")"
    else
        printf '%s\n' "$SOURCE_DATE_EPOCH" > "${build_dir}/build_date"
    fi

    [[ "${quiet}" == "y" ]] || _show_config
    _run_once _make_basefs
    _run_once _make_pacman_conf
    [[ -z "${gpg_key}" ]] || _run_once _export_gpg_publickey
    _run_once _make_packages
    [[ "${noaur}" = false ]] && _run_once _make_aur
    [[ "${nopkgbuild}" = false ]] && _run_once _make_pkgbuild
    _run_once _make_custom_airootfs
    _run_once _make_version
    _run_once _make_customize_airootfs
    _run_once _make_setup_mkinitcpio
    _run_once _make_pkglist
    _make_bootmodes
    _run_once _cleanup_pacstrap_dir
    _run_once _prepare_airootfs_image
}


# Build the bootstrap buildmode
_build_buildmode_bootstrap() {
    #local image_name="${iso_name}-bootstrap-${iso_version}-${arch}.tar.gz"
    local image_name="${tar_filename}"
    local run_once_mode="${buildmode}"
    #local buildmode_packages="${bootstrap_packages}"
    # Set the package list to use
    local buildmode_pkg_list=("${bootstrap_pkg_list[@]}")

    # Set up essential directory paths
    pacstrap_dir="${work_dir}/${arch}/bootstrap/root.${arch}"
    [[ -d "${work_dir}" ]] || install -d -- "${work_dir}"
    install -d -m 0755 -o 0 -g 0 -- "${pacstrap_dir}"

    [[ "${quiet}" == "y" ]] || _show_config
    _run_once _make_pacman_conf
    _run_once _make_packages
    _run_once _make_aur
    _run_once _make_pkgbuild
    _run_once _make_version
    _run_once _make_setup_mkinitcpio
    _run_once _make_pkglist
    _run_once _cleanup_pacstrap_dir
    _run_once _build_bootstrap_image
}

# Build the netboot buildmode
_build_buildmode_netboot() {
    local run_once_mode="${buildmode}"

    _build_iso_base
    if [[ -v cert_list ]]; then
        _run_once _sign_netboot_artifacts
    fi
    _run_once _export_netboot_artifacts
}

# Build the ISO buildmode
_build_buildmode_iso() {
    local image_name="${iso_filename}"
    local run_once_mode="${buildmode}"
    _build_iso_base
    _run_once _build_iso_image
}

# build all buildmodes
_build() {
    local buildmode
    local run_once_mode="build"

    for buildmode in "${buildmodes[@]}"; do
        _run_once "_build_buildmode_${buildmode}"
    done
}

# Parse options
ARGUMENT=("${DEFAULT_ARGUMENT[@]}" "${@}") OPTS=("a:" "b" "c:" "d" "e" "g:" "h" "j" "k:" "l:" "o:" "p:" "r" "t:" "u:" "w:" "x") OPTL=("arch:" "boot-splash" "comp-type:" "debug" "cleaning" "cleanup" "gpgkey:" "help" "lang:" "japanese" "kernel:" "out:" "password:" "comp-opts:" "user:" "work:" "bash-debug" "nocolor" "noconfirm" "nodepend" "gitversion" "msgdebug" "noloopmod" "tarball" "noiso" "noaur" "nochkver" "channellist" "config:" "noefi" "nodebug" "nosigcheck" "normwork" "log" "logpath:" "nolog" "nopkgbuild" "pacman-debug" "confirm" "tar-type:" "tar-opts:" "add-module:" "nogitversion" "cowspace:" "rerun" "depend" "loopmod")
GETOPT=(-o "$(printf "%s," "${OPTS[@]}")" -l "$(printf "%s," "${OPTL[@]}")" -- "${ARGUMENT[@]}")
getopt -Q "${GETOPT[@]}" || exit 1 # 引数エラー判定
readarray -t OPT < <(getopt "${GETOPT[@]}") # 配列に代入

eval set -- "${OPT[@]}"
_msg_debug "Argument: ${OPT[*]}"
unset OPT OPTS OPTL DEFAULT_ARGUMENT GETOPT

while true; do
    case "${1}" in
        -c | --comp-type)
            case "${2}" in
                "gzip" | "lzma" | "lzo" | "lz4" | "xz" | "zstd") sfs_comp="${2}" ;;
                *) _msg_error "Invaild compressors '${2}'" '1' ;;
            esac
            shift 2
            ;;
        -j | --japanese)
            _msg_error "This option is obsolete in AlterISO 3. To use Japanese, use \"-l ja\"." "1"
            ;;
        -k | --kernel)
            customized_kernel=true
            kernel="${2}"
            shift 2
            ;;
        -p | --password)
            customized_password=true
            password="${2}"
            shift 2
            ;;
        -t | --comp-opts)
            if [[ "${2}" = "reset" ]]; then
                sfs_comp_opt=()
            else
                IFS=" " read -r -a sfs_comp_opt <<< "${2}"
            fi
            shift 2
            ;;
        -u | --user)
            customized_username=true
            username="$(echo -n "${2}" | sed 's/ //g' | tr '[:upper:]' '[:lower:]')"
            shift 2
            ;;
        --nodebug)
            debug=false
            msgdebug=false
            bash_debug=false
            shift 1
            ;;
        --logpath)
            logging="${2}"
            customized_logpath=true
            shift 2
            ;;
        --tar-type)
            case "${2}" in
                "gzip" | "lzma" | "lzo" | "lz4" | "xz" | "zstd") tar_comp="${2}" ;;
                *) _msg_error "Invaild compressors '${2}'" '1' ;;
            esac
            shift 2
            ;;
        --tar-opts)
            IFS=" " read -r -a tar_comp_opt <<< "${2}"
            shift 2
            ;;
        --add-module)
            readarray -t -O "${#additional_modules[@]}" additional_modules < <(echo "${2}" | tr "," "\n")
            _msg_debug "Added modules: ${additional_modules[*]}"
            shift 2
            ;;
        -g | --gpgkey               ) gpg_key="${2}"     && shift 2 ;;
        -h | --help                 ) _usage 0                      ;;
        -a | --arch                 ) arch="${2}"        && shift 2 ;;
        -d | --debug                ) debug=true         && shift 1 ;;
        -e | --cleaning | --cleanup ) cleaning=true      && shift 1 ;;
        -b | --boot-splash          ) boot_splash=true   && shift 1 ;;
        -l | --lang                 ) locale_name="${2}" && shift 2 ;;
        -o | --out                  ) out_dir="${2}"     && shift 2 ;;
        -r | --tarball              ) tarball=true       && shift 1 ;;
        -w | --work                 ) work_dir="${2}"    && shift 2 ;;
        -x | --bash-debug           ) bash_debug=true    && shift 1 ;;
        --gitversion                ) gitversion=true    && shift 1 ;;
        --noconfirm                 ) noconfirm=true     && shift 1 ;;
        --confirm                   ) noconfirm=false    && shift 1 ;;
        --nodepend                  ) nodepend=true      && shift 1 ;;
        --nocolor                   ) nocolor=true       && shift 1 ;;
        --msgdebug                  ) msgdebug=true      && shift 1 ;;
        --noloopmod                 ) noloopmod=true     && shift 1 ;;
        --noiso                     ) noiso=true         && shift 1 ;;
        --noaur                     ) noaur=true         && shift 1 ;;
        --nochkver                  ) nochkver=true      && shift 1 ;;
        --noefi                     ) noefi=true         && shift 1 ;;
        --channellist               ) show_channel_list  && exit  0 ;;
        --config                    ) source "${2}"      ;  shift 2 ;;
        --pacman-debug              ) pacman_debug=true  && shift 1 ;;
        --nosigcheck                ) nosigcheck=true    && shift 1 ;;
        --normwork                  ) normwork=true      && shift 1 ;;
        --log                       ) logging=true       && shift 1 ;;
        --nolog                     ) logging=false      && shift 1 ;;
        --nopkgbuild                ) nopkgbuild=true    && shift 1 ;;
        --nogitversion              ) gitversion=false   && shift 1 ;;
        --cowspace                  ) cowspace="${2}"    && shift 2 ;;
        --rerun                     ) rerun=true         && shift 1 ;;
        --depend                    ) nodepend=false     && shift 1 ;;
        --loopmod                   ) noloopmod=false    && shift 1 ;;
        --                          ) shift 1            && break   ;;
        *)
            _msg_error "Argument exception error '${1}'"
            _msg_error "Please report this error to the developer." 1
            ;;
    esac
done

# Check root.
if (( ! "${EUID}" == 0 )); then
    _msg_warn "This script must be run as root." >&2
    _msg_warn "Re-run 'sudo ${0} ${ARGUMENT[*]}'"
    sudo "${0}" "${ARGUMENT[@]}" --rerun
    exit "${?}"
fi

# Show config message
_msg_debug "Use the default configuration file (${defaultconfig})."
[[ -f "${script_path}/custom.conf" ]] && _msg_debug "The default settings have been overridden by custom.conf"

# Debug mode
[[ "${bash_debug}" = true ]] && set -x -v

# Check for a valid channel name
if [[ -n "${1+SET}" ]]; then
    case "$(bash "${tools_dir}/channel.sh" --version "${alteriso_version}" -n check "${1}"; printf "%d" "${?}")" in
        "2")
            _msg_error "Invalid channel ${1}" "1"
            ;;
        "1")
            channel_dir="${1}"
            channel_name="$(basename "${1%/}")"
            ;;
        "0")
            channel_dir="${script_path}/channels/${1}"
            channel_name="${1}"
            ;;
    esac
else
    channel_dir="${script_path}/channels/${channel_name}"
fi

# Set vars
build_dir="${work_dir}/build/${arch}" cache_dir="${work_dir}/cache/${arch}" pacstrap_dir="${build_dir}/airootfs" isofs_dir="${build_dir}/iso" lockfile_dir="${build_dir}/lockfile" gitrev="$(cd "${script_path}"; git rev-parse --short HEAD)" preset_dir="${script_path}/presets"

# Create dir
for _dir in build_dir cache_dir pacstrap_dir isofs_dir lockfile_dir out_dir; do
    mkdir -p "$(eval "echo \$${_dir}")"
    _msg_debug "${_dir} is $(realpath "$(eval "echo \$${_dir}")")"
    eval "${_dir}=\"$(realpath "$(eval "echo \$${_dir}")")\""
done

# Set for special channels
if [[ -d "${channel_dir}.add" ]]; then
    channel_name="${1}"
    channel_dir="${channel_dir}.add"
elif [[ "${channel_name}" = "clean" ]]; then
   _run_cleansh
    exit 0
fi

# Check channel version
_msg_debug "channel path is ${channel_dir}"
if [[ ! "$(bash "${tools_dir}/channel.sh" --version "${alteriso_version}" ver "${channel_name}" | cut -d "." -f 1)" = "$(echo "${alteriso_version}" | cut -d "." -f 1)" ]] && [[ "${nochkver}" = false ]]; then
    _msg_error "This channel does not support Alter ISO 3."
    if [[ -d "${script_path}/.git" ]]; then
        _msg_error "Please run \"git checkout alteriso-2\"" "1"
    else
        _msg_error "Please download old version here.\nhttps://github.com/FascodeNet/alterlinux/releases" "1"
    fi
fi

prepare_env
prepare_build
show_settings
_validate_options
_build


#run_once make_pacman_conf
#run_once make_basefs # Mount airootfs
#run_once make_packages_repo
#[[ "${noaur}" = false ]] && run_once make_packages_aur
#[[ "${nopkgbuild}" = false ]] && run_once make_pkgbuild
#run_once make_customize_airootfs
#run_once make_setup_mkinitcpio
#[[ "${tarball}" = true ]] && run_once make_tarball
#if [[ "${noiso}" = false ]]; then
#    run_once make_syslinux
#    run_once make_isolinux
#    run_once make_boot
#    run_once make_boot_extra
#    if [[ "${noefi}" = false ]]; then
#        run_once make_efi
#        run_once make_efiboot
#    fi
#    run_once make_alteriso_info
#    run_once make_prepare
#    run_once make_overisofs
#    run_once make_iso
#fi

#[[ "${cleaning}" = true ]] && _run_cleansh

exit 0
