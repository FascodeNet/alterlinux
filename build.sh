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

set -eu

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
alteriso_version="3.1"

# Load config file
[[ ! -f "${defaultconfig}" ]] && "${tools_dir}/msg.sh" -a 'build.sh' error "${defaultconfig} was not found." && exit 1
for config in "${defaultconfig}" "${script_path}/custom.conf"; do
    [[ -f "${config}" ]] && source "${config}"
done

umask 0022

# Message common function
# msg_common [type] [-n] [string]
msg_common(){
    local _msg_opts=("-a" "build.sh") _type="${1}"
    shift 1
    [[ "${1}" = "-n" ]] && _msg_opts+=("-o" "-n") && shift 1
    [[ "${msgdebug}" = true ]] && _msg_opts+=("-x")
    [[ "${nocolor}"  = true ]] && _msg_opts+=("-n")
    _msg_opts+=("${_type}" "${@}")
    "${tools_dir}/msg.sh" "${_msg_opts[@]}"
}

# Show an INFO message
# ${1}: message string
msg_info() { msg_common info "${@}"; }

# Show an Warning message
# ${1}: message string
msg_warn() { msg_common warn "${@}"; }

# Show an debug message
# ${1}: message string
msg_debug() { 
    [[ "${debug}" = true ]] && msg_common debug "${@}"
    return 0
}

# Show an ERROR message then exit with status
# ${1}: message string
# ${2}: exit code number (with 0 does not exit)
msg_error() {
    msg_common error "${1}"
    [[ -n "${2:-}" ]] && exit "${2}"
}


# Usage: getclm <number>
# 標準入力から値を受けとり、引数で指定された列を抽出します。
getclm() { cut -d " " -f "${1}"; }

# Usage: echo_blank <number>
# 指定されたぶんの半角空白文字を出力します
echo_blank(){ yes " " 2> /dev/null  | head -n "${1}" | tr -d "\n"; }

_usage () {
    echo "usage ${0} [options] [channel]"
    echo
    echo "A channel is a profile of AlterISO settings."
    echo
    echo " General options:"
    echo "    -b | --boot-splash           Enable boot splash"
    echo "    -e | --cleanup | --cleaning  Enable post-build cleaning"
    echo "         --tarball               Build rootfs in tar.xz format"
    echo "    -h | --help                  This help message and exit"
    echo
    echo "    -a | --arch <arch>           Set iso architecture"
    echo "                                  Default: ${arch}"
    echo "    -c | --comp-type <comp_type> Set SquashFS compression type (gzip, lzma, lzo, xz, zstd)"
    echo "                                  Default: ${sfs_comp}"
    echo "    -g | --gpgkey <key>          Set gpg key"
    echo "                                  Default: ${gpg_key}"
    echo "    -l | --lang <lang>           Specifies the default language for the live environment"
    echo "                                  Default: ${locale_name}"
    echo "    -k | --kernel <kernel>       Set special kernel type.See below for available kernels"
    echo "                                  Default: ${defaultkernel}"
    echo "    -o | --out <out_dir>         Set the output directory"
    echo "                                  Default: ${out_dir}"
    echo "    -p | --password <password>   Set a live user password"
    echo "                                  Default: ${password}"
    echo "    -t | --comp-opts <options>   Set compressor-specific options."
    echo "                                  Default: empty"
    echo "    -u | --user <username>       Set user name"
    echo "                                  Default: ${username}"
    echo "    -w | --work <work_dir>       Set the working directory"
    echo "                                  Default: ${work_dir}"
    echo

    local blank="33" _arch _dirname _type

    for _type in "locale" "kernel"; do
        echo " ${_type} for each architecture:"
        for _arch in $(find "${script_path}/system/" -maxdepth 1 -mindepth 1 -name "${_type}-*" -print0 | xargs -I{} -0 basename {} | sed "s|${_type}-||g"); do
            echo -n "    ${_arch}$(echo_blank "$(( "${blank}" - 4 - "${#_arch}" ))")"
            "${tools_dir}/${_type}.sh" -a "${_arch}" show
        done
        echo
    done

    echo " Channel:"
    for _dirname in $(bash "${tools_dir}/channel.sh" --version "${alteriso_version}" -d -b -n show); do
        echo -ne "    ${_dirname%.add}$(echo_blank "$(( "${blank}" - 3 - "$(echo "${_dirname%.add}" | wc -m)" ))")"
        "${tools_dir}/channel.sh" --version "${alteriso_version}" --nocheck desc "${_dirname%.add}"
    done

    echo
    echo " Debug options: Please use at your own risk."
    echo "    -d | --debug                 Enable debug messages"
    echo "    -x | --bash-debug            Enable bash debug mode(set -xv)"
    echo "         --channellist           Output the channel list and exit"
    echo "         --gitversion            Add Git commit hash to image file version"
    echo "         --logpath <file>        Set log file path (use with --log)"
    echo "         --[no]log               (No) log ;re-run script with tee"
    echo "         --msgdebug              Enables output debugging"
    echo "         --noaur                 Ignore aur packages (Use only for debugging)"
    echo "         --nocolor               No output colored output"
    echo "         --[no]confirm           (No) check the settings before building"
    echo "         --nochkver              No check the version of the channel"
    echo "         --nodebug               No debug message"
    echo "         --noefi                 No efi boot (Use only for debugging)"
    echo "         --noloopmod             No check and load kernel module automatically"
    echo "         --nodepend              No check package dependencies before building"
    echo "         --noiso                 No build iso image (Use with --tarball)"
    echo "         --pacman-debug          Enable pacman debug mode"
    echo "         --normwork              No remove working dir"
    echo "         --nopkgbuild            Ignore PKGBUILD (Use only for debugging)"
    echo
    echo " Many packages are installed from AUR, so specifying --noaur can cause problems."
    echo
    [[ -n "${1:-}" ]] && exit "${1}"
}

# Unmount helper Usage: _umount <target>
_umount() { if mountpoint -q "${1}"; then umount -lf "${1}"; fi; }

# Mount helper Usage: _mount <source> <target>
_mount() { ! mountpoint -q "${2}" && [[ -f "${1}" ]] && [[ -d "${2}" ]] && mount "${1}" "${2}"; return 0; }

# Unmount work dir
umount_work () {
    local _args=("${build_dir}")
    [[ "${debug}" = true ]] && _args=("-d" "${_args[@]}")
    [[ "${nocolor}" = true ]] && _args+=("--nocolor")
    "${tools_dir}/umount.sh" "${_args[@]}"
}

# Mount airootfs on "${airootfs_dir}"
mount_airootfs () {
    mkdir -p "${airootfs_dir}"
    _mount "${airootfs_dir}.img" "${airootfs_dir}"
}


# Helper function to run make_*() only one time.
run_once() {
    set -eu
    if [[ ! -e "${lockfile_dir}/build.${1}" ]]; then
        msg_debug "Running ${1} ..."
        mount_airootfs
        eval "${@}"
        mkdir -p "${lockfile_dir}"; touch "${lockfile_dir}/build.${1}"
        umount_work
    else
        msg_debug "Skipped because ${1} has already been executed."
    fi
}

# Show message when file is removed
# remove <file> <file> ...
remove() {
    local _file
    for _file in "${@}"; do msg_debug "Removing ${_file}"; rm -rf "${_file}"; done
}

# 強制終了時にアンマウント
umount_trap() {
    local _status="${?}"
    umount_work
    msg_error "It was killed by the user.\nThe process may not have completed successfully."
    exit "${_status}"
}

# 設定ファイルを読み込む
# load_config [file1] [file2] ...
load_config() {
    local _file
    for _file in "${@}"; do [[ -f "${_file}" ]] && source "${_file}" && msg_debug "The settings have been overwritten by the ${_file}"; done
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
for_module(){
    local module
    for module in "${modules[@]}"; do eval "$(echo "${@}" | sed "s|{}|${module}|g")"; done
}

# pacstrapを実行
_pacstrap(){
    msg_info "Installing packages to ${airootfs_dir}/'..."
    local _args=("-c" "-G" "-M" "--" "${airootfs_dir}" "${@}")
    [[ "${pacman_debug}" = true ]] && _args+=(--debug)
    pacstrap -C "${build_dir}/pacman.conf" "${_args[@]}"
    msg_info "Packages installed successfully!"
}

# chroot環境でpacmanコマンドを実行
# /etc/alteriso-pacman.confを準備してコマンドを実行します
_run_with_pacmanconf(){
    sed "s|^CacheDir     =|#CacheDir    =|g" "${build_dir}/pacman.conf" > "${airootfs_dir}/etc/alteriso-pacman.conf"
    eval -- "${@}"
    remove "${airootfs_dir}/etc/alteriso-pacman.conf"
}

# コマンドをchrootで実行する
_chroot_run() {
    msg_debug "Run command in chroot\nCommand: ${*}"
    eval -- arch-chroot "${airootfs_dir}" "${@}"
}

_cleanup_common () {
    msg_info "Cleaning up what we can on airootfs..."

    # Delete pacman database sync cache files (*.tar.gz)
    [[ -d "${airootfs_dir}/var/lib/pacman" ]] && find "${airootfs_dir}/var/lib/pacman" -maxdepth 1 -type f -delete

    # Delete pacman database sync cache
    [[ -d "${airootfs_dir}/var/lib/pacman/sync" ]] && find "${airootfs_dir}/var/lib/pacman/sync" -delete

    # Delete pacman package cache
    [[ -d "${airootfs_dir}/var/cache/pacman/pkg" ]] && find "${airootfs_dir}/var/cache/pacman/pkg" -type f -delete

    # Delete all log files, keeps empty dirs.
    [[ -d "${airootfs_dir}/var/log" ]] && find "${airootfs_dir}/var/log" -type f -delete

    # Delete all temporary files and dirs
    [[ -d "${airootfs_dir}/var/tmp" ]] && find "${airootfs_dir}/var/tmp" -mindepth 1 -delete

    # Delete package pacman related files.
    find "${build_dir}" \( -name '*.pacnew' -o -name '*.pacsave' -o -name '*.pacorig' \) -delete

    # Delete all cache file
    [[ -d "${airootfs_dir}/var/cache" ]] && find "${airootfs_dir}/var/cache" -mindepth 1 -delete

    # Create an empty /etc/machine-id
    printf '' > "${airootfs_dir}/etc/machine-id"

    msg_info "Done!"
}

_cleanup_airootfs(){
    _cleanup_common
    # Delete all files in /boot
    [[ -d "${airootfs_dir}/boot" ]] && find "${airootfs_dir}/boot" -mindepth 1 -delete
}

_mkchecksum() {
    msg_info "Creating md5 checksum ..."
    echo "$(md5sum "${1}" | getclm 1) $(basename "${1}")" > "${1}.md5"
    msg_info "Creating sha256 checksum ..."
    echo "$(sha256sum "${1}" | getclm 1) $(basename "${1}")" > "${1}.sha256"
}

# Check the value of a variable that can only be set to true or false.
check_bool() {
    local _value _variable
    for _variable in "${@}"; do
        msg_debug -n "Checking ${_variable}..."
        eval ': ${'${_variable}':=""}'
        _value="$(eval echo '$'${_variable})"
        if [[ ! -v "${1}" ]] || [[ "${_value}"  = "" ]]; then
            [[ "${debug}" = true ]] && echo ; msg_error "The variable name ${_variable} is empty." "1"
        elif [[ ! "${_value}" = "true" ]] && [[ ! "${_value}" = "false" ]]; then
            [[ "${debug}" = true ]] && echo ; msg_error "The variable name ${_variable} is not of bool type (${_variable} = ${_value})" "1"
        elif [[ "${debug}" = true ]]; then
            echo -e " ${_value}"
        fi
    done
}

_run_cleansh(){
    bash $([[ "${bash_debug}" = true ]] && echo -n "-x" ) "${tools_dir}/clean.sh" -o -w "$(realpath "${build_dir}")" "$([[ "${debug}" = true ]] && printf "%s" "-d")" "$([[ "${noconfirm}" = true ]] && printf "%s" "-n")" "$([[ "${nocolor}" = true ]] && printf "%s" "--nocolor")"
}


# Check the build environment and create a directory.
prepare_env() {
    # Check packages
    if [[ "${nodepend}" = false ]]; then
        local _check_failed=false _pkg _result=0
        msg_info "Checking dependencies ..."
        if ! pacman -Qq pyalpm > /dev/null 2>&1; then
            msg_error "pyalpm is not installed." 1
        fi   
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
        [[ ! -d "/usr/lib/modules/$(uname -r)" ]] && msg_error "The currently running kernel module could not be found.\nProbably the system kernel has been updated.\nReboot your system to run the latest kernel." "1"
        [[ -z "$(lsmod | getclm 1 | grep -x "loop")" ]] && modprobe loop
    fi

    # Check work dir
    if [[ "${normwork}" = false ]]; then
        msg_info "Deleting the contents of ${build_dir}..."
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
    trap '_trap_remove_work' 1 2 3 15

    return 0
}


# Show settings.
show_settings() {
    if [[ "${boot_splash}" = true ]]; then
        msg_info "Boot splash is enabled."
        msg_info "Theme is used ${theme_name}."
    fi
    msg_info "Language is ${locale_fullname}."
    msg_info "Use the ${kernel} kernel."
    msg_info "Live username is ${username}."
    msg_info "Live user password is ${password}."
    msg_info "The compression method of squashfs is ${sfs_comp}."
    msg_info "Use the ${channel_name%.add} channel."
    msg_info "Build with architecture ${arch}."
    if [[ "${noconfirm}" = false ]]; then
        echo -e "\nPress Enter to continue or Ctrl + C to cancel."
        read
    fi
    trap 1 2 3 15
    trap 'umount_trap' 1 2 3 15

    return 0
}


# Preparation for build
prepare_build() {
    # Show alteriso version
    if [[ -d "${script_path}/.git" ]]; then
        cd  "${script_path}"
        msg_debug "The version of alteriso is $(git describe --long --tags | sed 's/\([^-]*-g\)/r\1/;s/-/./g')."
        cd "${OLDPWD}"
    fi

    # Load configs
    load_config "${channel_dir}/config.any" "${channel_dir}/config.${arch}"

    # Debug mode
    if [[ "${bash_debug}" = true ]]; then
        set -x -v
    fi

    # Legacy mode
    if [[ "$(bash "${tools_dir}/channel.sh" --version "${alteriso_version}" ver "${channel_name}")" = "3.0" ]]; then
        msg_warn "The module cannot be used because it works with Alter ISO3.0 compatibility."
        if [[ ! -z "${include_extra+SET}" ]]; then
            if [[ "${include_extra}" = true ]]; then
                modules=("base" "share" "share-extra" "calamares" "zsh-powerline")
            else
                modules=("base" "share")
            fi
        fi
    fi

    local module_check
    module_check(){
        msg_debug "Checking ${1} module ..."
        bash "${tools_dir}/module.sh" check "${1}" || msg_error "Module ${1} is not available." "1";
    }
    readarray -t modules < <(printf "%s\n" "${modules[@]}" | awk '!a[$0]++')
    for_module "module_check {}"
    for_module load_config "${module_dir}/{}/config.any" "${module_dir}/{}/config.${arch}"
    msg_debug "Loaded modules: ${modules[*]}"
    ! printf "%s\n" "${modules[@]}" | grep -x "share" >/dev/null 2>&1 && msg_warn "The share module is not loaded."

    # Set kernel
    [[ "${customized_kernel}" = false ]] && kernel="${defaultkernel}"

    # Parse files
    eval "$(bash "${tools_dir}/locale.sh" -s -a "${arch}" get "${locale_name}")"
    eval "$(bash "${tools_dir}/kernel.sh" -s -c "${channel_name}" -a "${arch}" get "${kernel}")"

    # Set username and password
    [[ "${customized_username}" = false ]] && username="${defaultusername}"
    [[ "${customized_password}" = false ]] && password="${defaultpassword}"

    # gitversion
    [[ "${gitversion}" = true ]] && iso_version="${iso_version}-${gitrev}"

    # Generate iso file name.
    local _channel_name="${channel_name%.add}-${locale_version}" 
    iso_filename="${iso_name}-${_channel_name}-${iso_version}-${arch}.iso"
    tar_filename="${iso_filename%.iso}.tar.xz"
    [[ "${nochname}" = true ]] && iso_filename="${iso_name}-${iso_version}-${arch}.iso"
    msg_debug "Iso filename is ${iso_filename}"

    # check bool
    check_bool boot_splash cleaning noconfirm nodepend customized_username customized_password noloopmod nochname tarball noiso noaur customized_syslinux norescue_entry debug bash_debug nocolor msgdebug noefi nosigcheck gitversion

    # Check architecture for each channel
    local _exit=0
    bash "${tools_dir}/channel.sh" --version "${alteriso_version}" -a "${arch}" -n -b check "${channel_name}" || _exit="${?}"
    if (( "${_exit}" != 0 )) && (( "${_exit}" != 1 )); then
        msg_error "${channel_name} channel does not support current architecture (${arch})." "1"
    fi

    # Run with tee
    if [[ ! "${logging}" = false ]]; then
        [[ "${customized_logpath}" = false ]] && logging="${out_dir}/${iso_filename%.iso}.log"
        mkdir -p "$(dirname "${logging}")" && touch "${logging}"
        msg_warn "Re-run sudo ${0} ${ARGUMENT[*]} --nodepend --nolog --nocolor 2>&1 | tee ${logging}"
        sudo "${0}" "${ARGUMENT[@]}" --nolog --nocolor --nodepend 2>&1 | tee "${logging}"
        exit "${?}"
    else
        unset ARGUMENT
    fi

    # Set argument of pkglist.sh
    pkglist_args=("-a" "${arch}" "-k" "${kernel}" "-c" "${channel_dir}" "-l" "${locale_name}")
    [[ "${boot_splash}"              = true ]] && pkglist_args+=("-b")
    [[ "${debug}"                    = true ]] && pkglist_args+=("-d")
    [[ "${memtest86}"                = true ]] && pkglist_args+=("-m")
    [[ "${nocolor}"                  = true ]] && pkglist_args+=("--nocolor")
    (( "${#additional_exclude_pkg[@]}" >= 1 )) && pkglist_args+=("-e" "${additional_exclude_pkg[*]}")
    pkglist_args+=("${modules[@]}")

    # Set argument of aur.sh and pkgbuild.sh
    [[ "${bash_debug}"   = true ]] && makepkg_script_args+=("-x")
    [[ "${pacman_debug}" = true ]] && makepkg_script_args+=("-d")

    return 0
}


# Setup custom pacman.conf with current cache directories.
make_pacman_conf() {
    # Pacman configuration file used only when building
    # If there is pacman.conf for each channel, use that for building
    local _pacman_conf _pacman_conf_list=("${script_path}/pacman-${arch}.conf" "${channel_dir}/pacman-${arch}.conf" "${script_path}/system/pacman-${arch}.conf")
    for _pacman_conf in "${_pacman_conf_list[@]}"; do
        if [[ -f "${_pacman_conf}" ]]; then
            build_pacman_conf="${_pacman_conf}"
            break
        fi
    done

    msg_debug "Use ${build_pacman_conf}"
    sed -r "s|^#?\\s*CacheDir.+|CacheDir     = ${cache_dir}|g" "${build_pacman_conf}" > "${build_dir}/pacman.conf"

    [[ "${nosigcheck}" = true ]] && sed -ir "s|^s*SigLevel.+|SigLevel = Never|g" "${build_pacman_conf}"

    [[ -n "$(find "${cache_dir}" -maxdepth 1 -name '*.pkg.tar.*' 2> /dev/null)" ]] && msg_info "Use cached package files in ${cache_dir}"

    # Share any architecture packages
    #while read -r _pkg; do
    #    if [[ ! -f "${cache_dir}/$(basename "${_pkg}")" ]]; then
    #        ln -s "${_pkg}" "${cache_dir}"
    #    fi
    #done < <(find "${cache_dir}/../" -type d -name "$(basename "${cache_dir}")" -prune -o -type f -name "*-any.pkg.tar.*" -printf "%p\n")

    return 0
}

# Base installation (airootfs)
make_basefs() {
    msg_info "Creating ext4 image of 32GiB..."
    truncate -s 32G -- "${airootfs_dir}.img"
    mkfs.ext4 -O '^has_journal,^resize_inode' -E 'lazy_itable_init=0' -m 0 -F -- "${airootfs_dir}.img" 32G
    tune2fs -c "0" -i "0" "${airootfs_dir}.img"
    msg_info "Done!"

    msg_info "Mounting ${airootfs_dir}.img on ${airootfs_dir}"
    mount_airootfs
    msg_info "Done!"
    return 0
}

# Additional packages (airootfs)
make_packages_repo() {
    msg_debug "pkglist.sh ${pkglist_args[*]}"
    readarray -t _pkglist < <("${tools_dir}/pkglist.sh" "${pkglist_args[@]}")

    # Create a list of packages to be finally installed as packages.list directly under the working directory.
    echo -e "# The list of packages that is installed in live cd.\n#\n" > "${build_dir}/packages.list"
    printf "%s\n" "${_pkglist[@]}" >> "${build_dir}/packages.list"

    # Install packages on airootfs
    _pacstrap "${_pkglist[@]}"

    return 0
}

make_packages_aur() {
    readarray -t _pkglist_aur < <("${tools_dir}/pkglist.sh" --aur "${pkglist_args[@]}")

    # Create a list of packages to be finally installed as packages.list directly under the working directory.
    echo -e "\n# AUR packages.\n#\n" >> "${build_dir}/packages.list"
    printf "%s\n" "${_pkglist_aur[@]}" >> "${build_dir}/packages.list"

    # prepare for yay
    cp -rf --preserve=mode "${script_path}/system/aur.sh" "${airootfs_dir}/root/aur.sh"

    # Run aur script
    _run_with_pacmanconf _chroot_run "bash" "/root/aur.sh" "${makepkg_script_args[@]}" "${_pkglist_aur[@]}"

    # Remove script
    remove "${airootfs_dir}/root/aur.sh"

    return 0
}

make_pkgbuild() {
    # Get PKGBUILD List
    local _pkgbuild_dirs=("${channel_dir}/pkgbuild.any" "${channel_dir}/pkgbuild.${arch}")
    for_module '_pkgbuild_dirs+=("${module_dir}/{}/pkgbuild.any" "${module_dir}/{}/pkgbuild.${arch}")'

    # Copy PKGBUILD to work
    mkdir -p "${airootfs_dir}/pkgbuilds/"
    for _dir in $(find "${_pkgbuild_dirs[@]}" -type f -name "PKGBUILD" -print0 2>/dev/null | xargs -0 -I{} realpath {} | xargs -I{} dirname {}); do
        msg_info "Find $(basename "${_dir}")"
        cp -r "${_dir}" "${airootfs_dir}/pkgbuilds/"
    done
    
    # copy buold script
    cp -rf --preserve=mode "${script_path}/system/pkgbuild.sh" "${airootfs_dir}/root/pkgbuild.sh"

    # Run build script
    _run_with_pacmanconf _chroot_run "bash" "/root/pkgbuild.sh" "${makepkg_script_args[@]}" "/pkgbuilds"

    # Remove script
    remove "${airootfs_dir}/root/pkgbuild.sh"

    return 0
}

# Customize installation (airootfs)
make_customize_airootfs() {
    # Overwrite airootfs with customize_airootfs.
    local _airootfs _airootfs_script_options _script _script_list _airootfs_list=() _main_script

    for_module '_airootfs_list+=("${module_dir}/{}/airootfs.any" "${module_dir}/{}/airootfs.${arch}")'
    _airootfs_list+=("${channel_dir}/airootfs.any" "${channel_dir}/airootfs.${arch}")

    for _airootfs in "${_airootfs_list[@]}";do
        if [[ -d "${_airootfs}" ]]; then
            msg_debug "Copying airootfs ${_airootfs} ..."
            cp -af "${_airootfs}"/* "${airootfs_dir}"
        fi
    done

    # Replace /etc/mkinitcpio.conf if Plymouth is enabled.
    if [[ "${boot_splash}" = true ]]; then
        cp -f "${script_path}/mkinitcpio/mkinitcpio-plymouth.conf" "${airootfs_dir}/etc/mkinitcpio.conf"
    else
        cp -f "${script_path}/mkinitcpio/mkinitcpio.conf" "${airootfs_dir}/etc/mkinitcpio.conf"
    fi
    
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
    _airootfs_script_options="-p '${password}' -k '${kernel} ${kernel_filename} ${kernel_mkinitcpio_profile}' -u '${username}' -o '${os_name}' -i '${install_dir}' -s '${usershell}' -a '${arch}' -g '${locale_gen_name}' -l '${locale_name}' -z '${locale_time}' -t ${theme_name}"
    [[ "${boot_splash}" = true ]] && _airootfs_script_options="${_airootfs_script_options} -b"
    [[ "${debug}" = true       ]] && _airootfs_script_options="${_airootfs_script_options} -d"
    [[ "${bash_debug}" = true  ]] && _airootfs_script_options="${_airootfs_script_options} -x"

    _main_script="root/customize_airootfs.sh"

    _script_list=(
        "${airootfs_dir}/root/customize_airootfs_${channel_name}.sh"
        "${airootfs_dir}/root/customize_airootfs_${channel_name%.add}.sh"
    )

    for_module '_script_list+=("${airootfs_dir}/root/customize_airootfs_{}.sh")'

    # Create script
    for _script in "${_script_list[@]}"; do
        if [[ -f "${_script}" ]]; then
            echo -e "\n$(cat "${_script}")" >> "${airootfs_dir}/${_main_script}"
            remove "${_script}"
        else
            msg_debug "${_script} was not found."
        fi
    done

    chmod 755 "${airootfs_dir}/${_main_script}"
    cp "${airootfs_dir}/${_main_script}" "${build_dir}/$(basename ${_main_script})"
    _chroot_run "${_main_script} ${_airootfs_script_options}"
    remove "${airootfs_dir}/${_main_script}"

    # /root permission https://github.com/archlinux/archiso/commit/d39e2ba41bf556674501062742190c29ee11cd59
    chmod -f 750 "${airootfs_dir}/root"

    return 0
}

# Copy mkinitcpio archiso hooks and build initramfs (airootfs)
make_setup_mkinitcpio() {
    local _hook
    mkdir -p "${airootfs_dir}/etc/initcpio/hooks" "${airootfs_dir}/etc/initcpio/install"

    for _hook in "archiso" "archiso_shutdown" "archiso_pxe_common" "archiso_pxe_nbd" "archiso_pxe_http" "archiso_pxe_nfs" "archiso_loop_mnt"; do
        cp "${script_path}/system/initcpio/hooks/${_hook}" "${airootfs_dir}/etc/initcpio/hooks"
        cp "${script_path}/system/initcpio/install/${_hook}" "${airootfs_dir}/etc/initcpio/install"
    done

    sed -i "s|/usr/lib/initcpio/|/etc/initcpio/|g" "${airootfs_dir}/etc/initcpio/install/archiso_shutdown"
    cp "${script_path}/system/initcpio/install/archiso_kms" "${airootfs_dir}/etc/initcpio/install"
    cp "${script_path}/system/initcpio/archiso_shutdown" "${airootfs_dir}/etc/initcpio"
    if [[ "${boot_splash}" = true ]]; then
        cp "${script_path}/mkinitcpio/mkinitcpio-archiso-plymouth.conf" "${airootfs_dir}/etc/mkinitcpio-archiso.conf"
    else
        cp "${script_path}/mkinitcpio/mkinitcpio-archiso.conf" "${airootfs_dir}/etc/mkinitcpio-archiso.conf"
    fi
    if [[ "${gpg_key}" ]]; then
      gpg --export "${gpg_key}" >"${build_dir}/gpgkey"
      exec 17<>"${build_dir}/gpgkey"
    fi

    _chroot_run "mkinitcpio -c /etc/mkinitcpio-archiso.conf -k /boot/${kernel_filename} -g /boot/archiso.img"

    [[ "${gpg_key}" ]] && exec 17<&-
    
    return 0
}

# Prepare kernel/initramfs ${install_dir}/boot/
make_boot() {
    mkdir -p "${isofs_dir}/${install_dir}/boot/${arch}"
    cp "${airootfs_dir}/boot/archiso.img" "${isofs_dir}/${install_dir}/boot/${arch}/archiso.img"
    cp "${airootfs_dir}/boot/${kernel_filename}" "${isofs_dir}/${install_dir}/boot/${arch}/${kernel_filename}"

    return 0
}

# Add other aditional/extra files to ${install_dir}/boot/
make_boot_extra() {
    if [[ -e "${airootfs_dir}/boot/memtest86+/memtest.bin" ]]; then
        install -m 0644 -- "${airootfs_dir}/boot/memtest86+/memtest.bin" "${isofs_dir}/${install_dir}/boot/memtest"
        install -d -m 0755 -- "${isofs_dir}/${install_dir}/boot/licenses/memtest86+/"
        install -m 0644 -- "${airootfs_dir}/usr/share/licenses/common/GPL2/license.txt" "${isofs_dir}/${install_dir}/boot/licenses/memtest86+/"
    fi

    local _ucode_image
    msg_info "Preparing microcode for the ISO 9660 file system..."

    for _ucode_image in {intel-uc.img,intel-ucode.img,amd-uc.img,amd-ucode.img,early_ucode.cpio,microcode.cpio}; do
        if [[ -e "${airootfs_dir}/boot/${_ucode_image}" ]]; then
            msg_info "Installimg ${_ucode_image} ..."
            install -m 0644 -- "${airootfs_dir}/boot/${_ucode_image}" "${isofs_dir}/${install_dir}/boot/"
            if [[ -e "${airootfs_dir}/usr/share/licenses/${_ucode_image%.*}/" ]]; then
                install -d -m 0755 -- "${isofs_dir}/${install_dir}/boot/licenses/${_ucode_image%.*}/"
                install -m 0644 -- "${airootfs_dir}/usr/share/licenses/${_ucode_image%.*}/"* "${isofs_dir}/${install_dir}/boot/licenses/${_ucode_image%.*}/"
            fi
        fi
    done
    msg_info "Done!"

    return 0
}

# Prepare /${install_dir}/boot/syslinux
make_syslinux() {
    mkdir -p "${isofs_dir}/syslinux"

    # 一時ディレクトリに設定ファイルをコピー
    mkdir -p "${build_dir}/syslinux/"
    cp -a "${script_path}/syslinux/"* "${build_dir}/syslinux/"
    if [[ -d "${channel_dir}/syslinux" ]] && [[ "${customized_syslinux}" = true ]]; then
        cp -af "${channel_dir}/syslinux"* "${build_dir}/syslinux/"
    fi

    # copy all syslinux config to work dir
    for _cfg in "${build_dir}/syslinux/"*.cfg; do
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
             s|%OS_NAME%|${os_name}|g;
             s|%KERNEL_FILENAME%|${kernel_filename}|g;
             s|%ARCH%|${arch}|g;
             s|%INSTALL_DIR%|${install_dir}|g" "${_cfg}" > "${isofs_dir}/syslinux/${_cfg##*/}"
    done

    # Replace the SYSLINUX configuration file with or without boot splash.
    local _use_config_name _no_use_config_name _pxe_or_sys
    if [[ "${boot_splash}" = true ]]; then
        _use_config_name=splash
        _no_use_config_name=nosplash
    else
        _use_config_name=nosplash
        _no_use_config_name=splash
    fi
    for _pxe_or_sys in "sys" "pxe"; do
        remove "${isofs_dir}/syslinux/archiso_${_pxe_or_sys}_${_no_use_config_name}.cfg"
        mv "${isofs_dir}/syslinux/archiso_${_pxe_or_sys}_${_use_config_name}.cfg" "${isofs_dir}/syslinux/archiso_${_pxe_or_sys}.cfg"
    done

    # Set syslinux wallpaper
    if [[ -f "${channel_dir}/splash.png" ]]; then
        cp "${channel_dir}/splash.png" "${isofs_dir}/syslinux"
    else
        cp "${script_path}/syslinux/splash.png" "${isofs_dir}/syslinux"
    fi

    # remove config
    local _remove_config
    function _remove_config() {
        remove "${isofs_dir}/syslinux/${1}"
        sed -i "s|$(grep "${1}" "${isofs_dir}/syslinux/archiso_sys_load.cfg")||g" "${isofs_dir}/syslinux/archiso_sys_load.cfg" 
    }

    [[ "${norescue_entry}" = true  ]] && _remove_config archiso_sys_rescue.cfg
    [[ "${memtest86}"      = false ]] && _remove_config memtest86.cfg

    # copy files
    cp "${airootfs_dir}/usr/lib/syslinux/bios/"*.c32 "${isofs_dir}/syslinux"
    cp "${airootfs_dir}/usr/lib/syslinux/bios/lpxelinux.0" "${isofs_dir}/syslinux"
    cp "${airootfs_dir}/usr/lib/syslinux/bios/memdisk" "${isofs_dir}/syslinux"


    if [[ -e "${isofs_dir}/syslinux/hdt.c32" ]]; then
        install -d -m 0755 -- "${isofs_dir}/syslinux/hdt"
        if [[ -e "${airootfs_dir}/usr/share/hwdata/pci.ids" ]]; then
            gzip -c -9 "${airootfs_dir}/usr/share/hwdata/pci.ids" > "${isofs_dir}/syslinux/hdt/pciids.gz"
        fi
        find "${airootfs_dir}/usr/lib/modules" -name 'modules.alias' -print -exec gzip -c -9 '{}' ';' -quit > "${isofs_dir}/syslinux/hdt/modalias.gz"
    fi

    return 0
}

# Prepare /isolinux
make_isolinux() {
    install -d -m 0755 -- "${isofs_dir}/syslinux"
    sed "s|%INSTALL_DIR%|${install_dir}|g" "${script_path}/system/isolinux.cfg" > "${isofs_dir}/syslinux/isolinux.cfg"
    install -m 0644 -- "${airootfs_dir}/usr/lib/syslinux/bios/isolinux.bin" "${isofs_dir}/syslinux/"
    install -m 0644 -- "${airootfs_dir}/usr/lib/syslinux/bios/isohdpfx.bin" "${isofs_dir}/syslinux/"

    return 0
}

# Prepare /EFI
make_efi() {
    local _bootfile _use_config_name="nosplash" _efi_config_list=() _efi_config
    [[ "${boot_splash}" = true ]] && _use_config_name="splash"
    _bootfile="$(basename "$(ls "${airootfs_dir}/usr/lib/systemd/boot/efi/systemd-boot"*".efi" )")"

    install -d -m 0755 -- "${isofs_dir}/EFI/boot"
    install -m 0644 -- "${airootfs_dir}/usr/lib/systemd/boot/efi/${_bootfile}" "${isofs_dir}/EFI/boot/${_bootfile#systemd-}"

    install -d -m 0755 -- "${isofs_dir}/loader/entries"
    sed "s|%ARCH%|${arch}|g;" "${script_path}/efiboot/${_use_config_name}/loader.conf" > "${isofs_dir}/loader/loader.conf"

    readarray -t _efi_config_list < <(find "${script_path}/efiboot/${_use_config_name}/" -mindepth 1 -maxdepth 1 -type f -name "archiso-usb*.conf" -printf "%f" | grep -v "rescue")
    [[ "${norescue_entry}" = false ]] && readarray -t _efi_config_list < <(find "${script_path}/efiboot/${_use_config_name}/" -mindepth 1 -maxdepth 1 -type f  -name "archiso-usb*rescue*.conf" -printf "%f")

    for _efi_config in "${_efi_config_list[@]}"; do
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
            s|%OS_NAME%|${os_name}|g;
            s|%KERNEL_FILENAME%|${kernel_filename}|g;
            s|%ARCH%|${arch}|g;
            s|%INSTALL_DIR%|${install_dir}|g" \
        "${_efi_config}" > "${isofs_dir}/loader/entries/$(basename "${_efi_config}" | sed "s|usb|${arch}|g")"
    done

    # edk2-shell based UEFI shell
    local _efi_shell_arch
    if [[ -d "${airootfs_dir}/usr/share/edk2-shell" ]]; then
        for _efi_shell_arch in $(find "${airootfs_dir}/usr/share/edk2-shell" -mindepth 1 -maxdepth 1 -type d -print0 | xargs -0 -I{} basename {}); do
            if [[ -f "${airootfs_dir}/usr/share/edk2-shell/${_efi_shell_arch}/Shell_Full.efi" ]]; then
                cp "${airootfs_dir}/usr/share/edk2-shell/${_efi_shell_arch}/Shell_Full.efi" "${isofs_dir}/EFI/shell_${_efi_shell_arch}.efi"
            elif [[ -f "${airootfs_dir}/usr/share/edk2-shell/${_efi_shell_arch}/Shell.efi" ]]; then
                cp "${airootfs_dir}/usr/share/edk2-shell/${_efi_shell_arch}/Shell.efi" "${isofs_dir}/EFI/shell_${_efi_shell_arch}.efi"
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

    mkdir -p "${build_dir}/efiboot/EFI/alteriso/${arch}"
    cp "${isofs_dir}/${install_dir}/boot/${arch}/${kernel_filename}" "${build_dir}/efiboot/EFI/alteriso/${arch}/${kernel_filename}.efi"
    cp "${isofs_dir}/${install_dir}/boot/${arch}/archiso.img" "${build_dir}/efiboot/EFI/alteriso/${arch}/archiso.img"

    local _ucode_image _efi_config _use_config_name="nosplash" _bootfile
    for _ucode_image in "${airootfs_dir}/boot/"{intel-uc.img,intel-ucode.img,amd-uc.img,amd-ucode.img,early_ucode.cpio,microcode.cpio}; do
        [[ -e "${_ucode_image}" ]] && cp "${_ucode_image}" "${build_dir}/efiboot/EFI/alteriso/"
    done

    mkdir -p "${build_dir}/efiboot/EFI/boot"

    cp "${airootfs_dir}/usr/share/efitools/efi/HashTool.efi" "${build_dir}/efiboot/EFI/boot/"

    _bootfile="$(basename "$(ls "${airootfs_dir}/usr/lib/systemd/boot/efi/systemd-boot"*".efi" )")"
    cp "${airootfs_dir}/usr/lib/systemd/boot/efi/${_bootfile}" "${build_dir}/efiboot/EFI/boot/${_bootfile#systemd-}"

    [[ "${boot_splash}" = true ]] && _use_config_name="splash"
    mkdir -p "${build_dir}/efiboot/loader/entries"
    sed "s|%ARCH%|${arch}|g;" "${script_path}/efiboot/${_use_config_name}/loader.conf" > "${build_dir}/efiboot/loader/loader.conf"

    find "${isofs_dir}/loader/entries/" -maxdepth 1 -mindepth 1 -name "uefi-shell*" -type f -printf "%p\0" | xargs -0 -I{} cp {} "${build_dir}/efiboot/loader/entries/"

    readarray -t _efi_config_list < <(find "${script_path}/efiboot/${_use_config_name}/" -mindepth 1 -maxdepth 1 -type f -name "archiso-cd*.conf" -printf "%f" | grep -v "rescue")
    [[ "${norescue_entry}" = false ]] && readarray -t _efi_config_list < <(find "${script_path}/efiboot/${_use_config_name}/" -mindepth 1 -maxdepth 1 -type f  -name "archiso-cd*rescue*.conf" -printf "%f")

    for _efi_config in "${_efi_config_list[@]}"; do
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
            s|%OS_NAME%|${os_name}|g;
            s|%KERNEL_FILENAME%|${kernel_filename}|g;
            s|%ARCH%|${arch}|g;
            s|%INSTALL_DIR%|${install_dir}|g" \
        "${_efi_config}" > "${build_dir}/efiboot/loader/entries/$(basename "${_efi_config}" | sed "s|cd|${arch}|g")"
    done

    find "${isofs_dir}/EFI" -maxdepth 1 -mindepth 1 -name "shell*.efi" -printf "%p\0" | xargs -0 -I{} cp {} "${build_dir}/efiboot/EFI/"
    umount -d "${build_dir}/efiboot"

    return 0
}

# Compress tarball
make_tarball() {
    # backup airootfs.img for tarball
    msg_info "Copying airootfs.img ..."
    cp "${airootfs_dir}.img" "${airootfs_dir}.img.org"

    # Run script
    mount_airootfs
    [[ -f "${airootfs_dir}/root/optimize_for_tarball.sh" ]] && _chroot_run "bash /root/optimize_for_tarball.sh -u ${username}"

    _cleanup_common
    _chroot_run "mkinitcpio -P"

    remove "${airootfs_dir}/root/optimize_for_tarball.sh"

    mkdir -p "${out_dir}"
    msg_info "Creating tarball..."
    cd -- "${airootfs_dir}"
    tar -v -J -p -c -f "${out_dir}/${tar_filename}" ./*
    cd -- "${OLDPWD}"

    _mkchecksum "${out_dir}/${tar_filename}"
    msg_info "Done! | $(ls -sh "${out_dir}/${tar_filename}")"

    remove "${airootfs_dir}.img"
    mv "${airootfs_dir}.img.org" "${airootfs_dir}.img"

    [[ "${noiso}" = true ]] && msg_info "The password for the live user and root is ${password}."
    
    return 0
}


# Build airootfs filesystem image
make_prepare() {
    mount_airootfs

    # Create packages list
    msg_info "Creating a list of installed packages on live-enviroment..."
    pacman-key --init
    pacman -Q --sysroot "${airootfs_dir}" | tee "${isofs_dir}/${install_dir}/pkglist.${arch}.txt" "${build_dir}/packages-full.list" > /dev/null

    # Cleanup
    remove "${airootfs_dir}/root/optimize_for_tarball.sh"
    _cleanup_airootfs

    # Create squashfs
    mkdir -p -- "${isofs_dir}/${install_dir}/${arch}"
    msg_info "Creating SquashFS image, this may take some time..."
    mksquashfs "${airootfs_dir}" "${build_dir}/iso/${install_dir}/${arch}/airootfs.sfs" -noappend -comp "${sfs_comp}" "${sfs_comp_opt[@]}"

    # Create checksum
    msg_info "Creating checksum file for self-test..."
    echo "$(sha512sum "${isofs_dir}/${install_dir}/${arch}/airootfs.sfs" | getclm 1) airootfs.sfs" > "${isofs_dir}/${install_dir}/${arch}/airootfs.sha512"
    msg_info "Done!"

    # Sign with gpg
    if [[ -v gpg_key ]] && (( "${#gpg_key}" != 0 )); then
        msg_info "Creating signature file ($gpg_key) ..."
        cd -- "${isofs_dir}/${install_dir}/${arch}"
        gpg --detach-sign --default-key "${gpg_key}" "airootfs.sfs"
        cd -- "${OLDPWD}"
        msg_info "Done!"
    fi

    umount_work

    [[ "${cleaning}" = true ]] && remove "${airootfs_dir}" "${airootfs_dir}.img"

    return 0
}

make_alteriso_info(){
    # iso version info
    if [[ "${include_info}" = true ]]; then
        local _info_file="${isofs_dir}/alteriso-info" _version="${iso_version}"
        remove "${_info_file}"; touch "${_info_file}"
        [[ -d "${script_path}/.git" ]] && [[ "${gitversion}" = false ]] && _version="${iso_version}-${gitrev}"
        "${tools_dir}/alteriso-info.sh" -a "${arch}" -b "${boot_splash}" -c "${channel_name%.add}" -d "${iso_publisher}" -k "${kernel}" -o "${os_name}" -p "${password}" -u "${username}" -v "${_version}" > "${_info_file}"
    fi

    return 0
}

# Add files to the root of isofs
make_overisofs() {
    local _over_isofs_list _isofs
    _over_isofs_list=("${channel_dir}/over_isofs.any""${channel_dir}/over_isofs.${arch}")
    for_module '_over_isofs_list+=("${module_dir}/{}/over_isofs.any""${module_dir}/{}/over_isofs.${arch}")'
    for _isofs in "${_over_isofs_list[@]}"; do
        [[ -d "${_isofs}" ]] && cp -af "${_isofs}"/* "${isofs_dir}"
    done

    return 0
}

# Build ISO
make_iso() {
    local _iso_efi_boot_args=()
    # If exists, add an EFI "El Torito" boot image (FAT filesystem) to ISO-9660 image.
    if [[ -f "${build_dir}/efiboot.img" ]]; then
        _iso_efi_boot_args=(-append_partition 2 C12A7328-F81F-11D2-BA4B-00A0C93EC93B "${build_dir}/efiboot.img" -appended_part_as_gpt -eltorito-alt-boot -e --interval:appended_partition_2:all:: -no-emul-boot -isohybrid-gpt-basdat)
    fi

    mkdir -p -- "${out_dir}"
    msg_info "Creating ISO image..."
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -joliet \
        -joliet-long \
        -rational-rock \
        -volid "${iso_label}" \
        -appid "${iso_application}" \
        -publisher "${iso_publisher}" \
        -preparer "prepared by AlterISO" \
        -eltorito-boot syslinux/isolinux.bin \
        -eltorito-catalog syslinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -isohybrid-mbr "${build_dir}/iso/syslinux/isohdpfx.bin" \
        "${_iso_efi_boot_args[@]}" \
        -output "${out_dir}/${iso_filename}" \
        "${build_dir}/iso/"
    _mkchecksum "${out_dir}/${iso_filename}"
    msg_info "Done! | $(ls -sh -- "${out_dir}/${iso_filename}")"

    msg_info "The password for the live user and root is ${password}."

    return 0
}


# Parse options
OPTS=("a:" "b" "c:" "d" "e" "g:" "h" "j" "k:" "l:" "o:" "p:" "r" "t:" "u:" "w:" "x")
OPTL=("arch:" "boot-splash" "comp-type:" "debug" "cleaning" "cleanup" "gpgkey:" "help" "lang:" "japanese" "kernel:" "out:" "password:" "comp-opts:" "user:" "work:" "bash-debug" "nocolor" "noconfirm" "nodepend" "gitversion" "msgdebug" "noloopmod" "tarball" "noiso" "noaur" "nochkver" "channellist" "config:" "noefi" "nodebug" "nosigcheck" "normwork" "log" "logpath:" "nolog" "nopkgbuild" "pacman-debug" "confirm")
if ! OPT=$(getopt -o "$(printf "%s," "${OPTS[@]}")" -l "$(printf "%s," "${OPTL[@]}")" --  "${@}" "${DEFAULT_ARGUMENT[@]}"); then
    exit 1
fi

eval set -- "${OPT}"
msg_debug "Argument: ${OPT}"
unset OPT OPTS OPTL DEFAULT_ARGUMENT

while true; do
    case "${1}" in
        -a | --arch)
            arch="${2}"
            shift 2
            ;;
        -b | --boot-splash)
            boot_splash=true
            shift 1
            ;;
        -c | --comp-type)
            case "${2}" in
                "gzip" | "lzma" | "lzo" | "lz4" | "xz" | "zstd") sfs_comp="${2}" ;;
                *) msg_error "Invaild compressors '${2}'" '1' ;;
            esac
            shift 2
            ;;
        -d | --debug)
            debug=true
            shift 1
            ;;
        -e | --cleaning | --cleanup)
            cleaning=true
            shift 1
            ;;
        -g | --gpgkey)
            gpg_key="${2}"
            shift 2
            ;;
        -h | --help)
            _usage
            exit 0
            ;;
        -j | --japanese)
            msg_error "This option is obsolete in AlterISO 3. To use Japanese, use \"-l ja\"." "1"
            ;;
        -k | --kernel)
            customized_kernel=true
            kernel="${2}"
            shift 2
            ;;
        -l | --lang)
            locale_name="${2}"
            shift 2
            ;;
        -o | --out)
            out_dir="${2}"
            shift 2
            ;;
        -p | --password)
            customized_password=true
            password="${2}"
            shift 2
            ;;
        -r | --tarball)
            tarball=true
            shift 1
            ;;
        -t | --comp-opts)
            if [[ "${2}" = "reset" ]]; then
                sfs_comp_opt=()
            else
                sfs_comp_opt=(${2})
            fi
            shift 2
            ;;
        -u | --user)
            customized_username=true
            username="$(echo -n "${2}" | sed 's/ //g' | tr '[:upper:]' '[:lower:]')"
            shift 2
            ;;
        -w | --work)
            work_dir="${2}"
            shift 2
            ;;
        -x | --bash-debug)
            debug=true
            bash_debug=true
            shift 1
            ;;
        --noconfirm)
            noconfirm=true
            shift 1
            ;;
        --confirm)
            noconfirm=false
            shift 1
            ;;
        --nodepend)
            nodepend=true
            shift 1
            ;;
        --nocolor)
            nocolor=true
            shift 1
            ;;
        --gitversion)
            if [[ -d "${script_path}/.git" ]]; then
                gitversion=true
            else
                msg_error "There is no git directory. You need to use git clone to use this feature." "1"
            fi
            shift 1
            ;;
        --msgdebug)
            msgdebug=true;
            shift 1
            ;;
        --noloopmod)
            noloopmod=true
            shift 1
            ;;
        --noiso)
            noiso=true
            shift 1
            ;;
        --noaur)
            noaur=true
            shift 1
            ;;
        --nochkver)
            nochkver=true
            shift 1
            ;;
        --nodebug)
            debug=false
            msgdebug=false
            bash_debug=false
            shift 1
            ;;
        --noefi)
            noefi=true
            shift 1
            ;;
        --channellist)
            show_channel_list
            exit 0
            ;;
        --config)
            source "${2}"
            shift 2
            ;;
        --pacman-debug)
            pacman_debug=true
            shift 1
            ;;
        --nosigcheck)
            nosigcheck=true
            shift 1
            ;;
        --normwork)
            normwork=true
            shift 1
            ;;
        --log)
            logging=true
            shift 1
            ;;
        --logpath)
            logging="${2}"
            customized_logpath=true
            shift 2
            ;;
        --nolog)
            logging=false
            shift 1
            ;;
        --nopkgbuild)
            nopkgbuild=true
            shift 1
            ;;
        --)
            shift
            break
            ;;
        *)
            msg_error "Invalid argument '${1}'"
            _usage 1
            ;;
    esac
done

# Check root.
if (( ! "${EUID}" == 0 )); then
    msg_warn "This script must be run as root." >&2
    msg_warn "Re-run 'sudo ${0} ${ARGUMENT[*]}'"
    sudo "${0}" "${ARGUMENT[@]}"
    exit "${?}"
fi

# Show config message
msg_debug "Use the default configuration file (${defaultconfig})."
[[ -f "${script_path}/custom.conf" ]] && msg_debug "The default settings have been overridden by custom.conf"

# Debug mode
[[ "${bash_debug}" = true ]] && set -x -v

# Check for a valid channel name
if [[ -n "${1+SET}" ]]; then
    case "$(bash "${tools_dir}/channel.sh" --version "${alteriso_version}" -n check "${1}"; printf "${?}")" in
        "2")
            msg_error "Invalid channel ${1}" "1"
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
work_dir="$(realpath "${work_dir}")"
build_dir="${work_dir}/build/${arch}"
cache_dir="${work_dir}/cache/${arch}"
airootfs_dir="${build_dir}/airootfs"
isofs_dir="${build_dir}/iso"
lockfile_dir="${build_dir}/lockfile"
gitrev="$(cd "${script_path}"; git rev-parse --short HEAD)"

# Create dir
for _dir in "${build_dir}" "${cache_dir}" "${airootfs_dir}" "${isofs_dir}" "${lockfile_dir}"; do
    mkdir -p "${_dir}"
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
msg_debug "channel path is ${channel_dir}"
if [[ ! "$(bash "${tools_dir}/channel.sh" --version "${alteriso_version}" ver "${channel_name}" | cut -d "." -f 1)" = "$(echo "${alteriso_version}" | cut -d "." -f 1)" ]] && [[ "${nochkver}" = false ]]; then
    msg_error "This channel does not support Alter ISO 3."
    if [[ -d "${script_path}/.git" ]]; then
        msg_error "Please run \"git checkout alteriso-2\"" "1"
    else
        msg_error "Please download old version here.\nhttps://github.com/FascodeNet/alterlinux/releases" "1"
    fi
fi

set -eu

prepare_env
prepare_build
show_settings
run_once make_pacman_conf
run_once make_basefs # Mount airootfs
run_once make_packages_repo
[[ "${noaur}" = false ]] && run_once make_packages_aur
[[ "${nopkgbuild}" = false ]] && run_once make_pkgbuild
run_once make_customize_airootfs
run_once make_setup_mkinitcpio
[[ "${tarball}" = true ]] && run_once make_tarball
if [[ "${noiso}" = false ]]; then
    run_once make_syslinux
    run_once make_isolinux
    run_once make_boot
    run_once make_boot_extra
    if [[ "${noefi}" = false ]]; then
        run_once make_efi
        run_once make_efiboot
    fi
    run_once make_alteriso_info
    run_once make_prepare
    run_once make_overisofs
    run_once make_iso
fi

[[ "${cleaning}" = true ]] && _run_cleansh

exit 0
