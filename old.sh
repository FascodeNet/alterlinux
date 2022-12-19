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
# SPDX-License-Identifier: GPL-3.0-or-later

set -e -u

# Control the environment
umask 0022
export LC_ALL="C"
[[ -v SOURCE_DATE_EPOCH ]] || printf -v SOURCE_DATE_EPOCH '%(%s)T' -1
export SOURCE_DATE_EPOCH
set -E

# Internal config
# Do not change these values.
script_path="$(cd "$(dirname "${0}")" || exit 1 ; pwd)"
defaultconfig="${script_path}/default.conf"
tools_dir="${script_path}/tools" module_dir="${script_path}/modules"
customized_username=false customized_password=false customized_kernel=false customized_logpath=false
pkglist_args=() makepkg_script_args=() modules=() norepopkg=()
legacy_mode=false rerun=false
DEFAULT_ARGUMENT="" ARGUMENT=("${@}")
alteriso_version="3.1"
use_bootloader_type="nosplash"
not_use_bootloader_type="splash"


#-- AlterISO 4.0 Variables --#
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito')
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
sign_netboot_artifacts=""
cert_list=()
# adapted from GRUB_EARLY_INITRD_LINUX_STOCK in https://git.savannah.gnu.org/cgit/grub.git/tree/util/grub-mkconfig.in
readonly ucodes=('intel-uc.img' 'intel-ucode.img' 'amd-uc.img' 'amd-ucode.img' 'early_ucode.cpio' 'microcode.cpio')

# Load config file
[[ ! -f "${defaultconfig}" ]] && "${tools_dir}/msg.sh" -a 'build.sh' error "${defaultconfig} was not found." && exit 1
for config in "${defaultconfig}" "${script_path}/custom.conf" "${script_path}/lib/"*".sh"; do
    [[ -f "${config}" ]] && source "${config}" && loaded_files+=("${config}")
done

# Message common function
# _msg_common [type] [-n] [string]
_msg_common(){
    local _msg_opts=("-a" "build.sh") _type="${1}" && shift 1
    [[ "${1}" = "-n" ]] && _msg_opts+=("-o" "-n") && shift 1
    [[ "${msgdebug}" = true ]] && _msg_opts+=("-x")
    [[ "${nocolor}"  = true ]] && _msg_opts+=("-n")
    _msg_opts+=("${_type}" "${@}")
    #"${tools_dir}/vlang/msg/msg"  "${_msg_opts[@]}"
    "${tools_dir}/msg.sh" "${_msg_opts[@]}"
}

# Show an INFO message
# ${1}: message string
_msg_info() { _msg_common info "${@}"; }

# Show an Warning message
# ${1}: message string
_msg_warn() { _msg_common warn "${@}"; }
_msg_warning() { _msg_warn "${@}"; }

# Show an debug message
# ${1}: message string
_msg_debug() { 
    [[ "${debug}" = true ]] && _msg_common debug "${@}" || return 0
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
_msg_error() {
    _msg_common error "${1}"
    { [[ -n "${2:-""}" ]] && (( "${2}" > 0 )); } && exit "${2}" || return 0
}

#-- Compile V Tools --#
while read -r _dir; do
    if [[ -e "$_dir/main.v" ]]; then
        v -o "$_dir/$(basename "$_dir")" "$_dir/main.v"
    fi
done < <(find "${tools_dir}/vlang" -mindepth 1 -maxdepth 1 -type d)
unset _dir

#-- AlterISO 3.2 functions --#
# Build confirm
_build_confirm() {
    if [[ "${noconfirm}" = false ]]; then
        echo -e "\nPress Enter to continue or Ctrl + C to cancel."
        read -r
    fi
    trap HUP INT QUIT TERM
    trap 'umount_trap' HUP INT QUIT TERM
    trap 'error_exit_trap $LINENO' ERR
    return 0
}

# Shows configuration options.
_show_config() {
    local build_date
    printf -v build_date '%(%FT%R%z)T' "${SOURCE_DATE_EPOCH}"
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
    _msg_info "Code signing certificates:   ${cert_list[*]:-None}"
    _msg_info "                  Profile:   ${channel_name}"
    _msg_info "Pacman configuration file:   ${pacman_conf}"
    _msg_info "          Image file name:   ${image_name:-None}"
    _msg_info "         ISO volume label:   ${iso_label}"
    _msg_info "            ISO publisher:   ${iso_publisher}"
    _msg_info "          ISO application:   ${iso_application}"
    _msg_info "               Boot modes:   ${bootmodes[*]:-None}"
    _msg_info "                 Plymouth:   ${boot_splash}"
    _msg_info "           Plymouth theme:   ${theme_name}"
    _msg_info "                 Language:   ${locale_name}"
    
    _build_confirm
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
        /\[options\]/a HookDir = ${pacstrap_dir}/etc/pacman.d/hooks/
        /\[options\]/a DBPath  = ${pacstrap_dir}/var/lib/pacman/" > "${build_dir}/${buildmode}.pacman.conf"

    [[ "${nosigcheck}" = true ]] && sed -i "/SigLevel/d; /\[options\]/a SigLebel = Never" "${pacman_conf}"

    [[ -n "$(find "${cache_dir}" -maxdepth 1 -name '*.pkg.tar.*' 2> /dev/null)" ]] && _msg_info "Use cached package files in ${cache_dir}"

    _msg_info "Done!"
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

_make_customize_bootstrap(){
    # backup airootfs.img for tarball
    _msg_debug "Tarball filename is ${tar_filename}"
    _msg_info "Copying airootfs.img ..."
    cp "${pacstrap_dir}.img" "${pacstrap_dir}.img.org"

    # Run script
    umount_work
    mount_airootfs
    if [[ -f "${pacstrap_dir}/root/optimize_for_tarball.sh" ]]; then 
        _chroot_run "bash" "/root/optimize_for_tarball.sh" -u "${username}"
        remove "${pacstrap_dir}/root/optimize_for_tarball.sh"
    fi
}


# Copy mkinitcpio archiso hooks and build initramfs (airootfs)
_make_setup_mkinitcpio() {
    local _hook
    mkdir -p "${pacstrap_dir}/etc/initcpio/hooks" "${pacstrap_dir}/etc/initcpio/install"

    for _hook in "archiso" "archiso_pxe_common" "archiso_pxe_nbd" "archiso_pxe_http" "archiso_pxe_nfs" "archiso_loop_mnt"; do
        cp "${script_path}/system/initcpio/hooks/${_hook}" "${pacstrap_dir}/etc/initcpio/hooks"
        cp "${script_path}/system/initcpio/install/${_hook}" "${pacstrap_dir}/etc/initcpio/install"
    done

    sed -i "s|%COWSPACE%|${cowspace}|g" "${pacstrap_dir}/etc/initcpio/hooks/archiso"
    cp "${script_path}/system/initcpio/install/archiso_kms" "${pacstrap_dir}/etc/initcpio/install"
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



# Parse options
ARGUMENT=("${DEFAULT_ARGUMENT[@]}" "${@}") OPTS=("a:" "b" "c:" "d" "e" "g:" "h" "j" "k:" "l:" "o:" "p:" "r" "t:" "u:" "w:" "x") OPTL=("arch:" "boot-splash" "comp-type:" "debug" "cleaning" "cleanup" "gpgkey:" "help" "lang:" "japanese" "kernel:" "out:" "password:" "comp-opts:" "user:" "work:" "bash-debug" "nocolor" "noconfirm" "nodepend" "gitversion" "msgdebug" "noloopmod" "tarball" "noiso" "noaur" "nochkver" "channellist" "config:" "noefi" "nodebug" "nosigcheck" "normwork" "log" "logpath:" "nolog" "nopkgbuild" "pacman-debug" "confirm" "add-module:" "nogitversion" "cowspace:" "rerun" "depend" "loopmod" "cert:")
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
            customized_kernel=true kernel="${2}"
            shift 2
            ;;
        -p | --password)
            customized_password=true password="${2}"
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
            debug=false msgdebug=false bash_debug=false
            shift 1
            ;;
        --logpath)
            logging="${2}" customized_logpath=true
            shift 2
            ;;
        --add-module)
            readarray -t -O "${#additional_modules[@]}" additional_modules < <(echo "${2}" | tr "," "\n")
            _msg_debug "Added modules: ${additional_modules[*]}"
            shift 2
            ;;
        --cert)
            sign_netboot_artifacts="y"
            IFS=" " read -a -r override_cert_list <<< "${2}"
            cert_list+=("${override_cert_list[@]}")
            unset override_cert_list
            shift 2
            ;;
        -g | --gpgkey               ) gpg_key="${2}"           && shift 2 ;;
        -h | --help                 ) _usage 0                      ;;
        -a | --arch                 ) arch="${2}"              && shift 2 ;;
        -d | --debug                ) debug=true               && shift 1 ;;
        -e | --cleaning | --cleanup ) cleaning=true            && shift 1 ;;
        -b | --boot-splash          ) boot_splash=true         && shift 1 ;;
        -l | --lang                 ) locale_name="${2}"       && shift 2 ;;
        -o | --out                  ) out_dir="${2}"           && shift 2 ;;
        -r | --tarball              ) tarball=true             && shift 1 ;;
        -w | --work                 ) work_dir="${2}"          && shift 2 ;;
        -x | --bash-debug           ) bash_debug=true          && shift 1 ;;
        --gitversion                ) gitversion=true          && shift 1 ;;
        --noconfirm                 ) noconfirm=true           && shift 1 ;;
        --confirm                   ) noconfirm=false          && shift 1 ;;
        --nodepend                  ) nodepend=true            && shift 1 ;;
        --nocolor                   ) nocolor=true             && shift 1 ;;
        --msgdebug                  ) msgdebug=true            && shift 1 ;;
        --noloopmod                 ) noloopmod=true           && shift 1 ;;
        --noiso                     ) noiso=true               && shift 1 ;;
        --noaur                     ) noaur=true               && shift 1 ;;
        --nochkver                  ) nochkver=true            && shift 1 ;;
        --noefi                     ) noefi=true               && shift 1 ;;
        --channellist               ) _channel_name_full_list  && exit  0 ;;
        --config                    ) source "${2}"            ;  shift 2 ;;
        --pacman-debug              ) pacman_debug=true        && shift 1 ;;
        --nosigcheck                ) nosigcheck=true          && shift 1 ;;
        --normwork                  ) normwork=true            && shift 1 ;;
        --log                       ) logging=true             && shift 1 ;;
        --nolog                     ) logging=false            && shift 1 ;;
        --nopkgbuild                ) nopkgbuild=true          && shift 1 ;;
        --nogitversion              ) gitversion=false         && shift 1 ;;
        --cowspace                  ) cowspace="${2}"          && shift 2 ;;
        --rerun                     ) rerun=true               && shift 1 ;;
        --depend                    ) nodepend=false           && shift 1 ;;
        --loopmod                   ) noloopmod=false          && shift 1 ;;
        --                          ) shift 1                  && break   ;;
        *)
            _msg_error "Argument exception error '${1}'"
            _msg_error "Please report this error to the developer." 1
            ;;
    esac
done


# Show config message
_msg_debug "Use the default configuration file (${defaultconfig})."
[[ -f "${script_path}/custom.conf" ]] && _msg_debug "The default settings have been overridden by custom.conf"

# Debug mode
[[ "${bash_debug}" = true ]] && set -x -v

# Check for a valid channel name
if [[ -n "${1+SET}" ]]; then
    _msg_debug "Channel check status is $(_channel_check "${1}" >/dev/null ; printf "%d" "${?}")"
    case "$(_channel_check "${1}" >/dev/null ; printf "%d" "${?}")" in
        "2")
            _msg_error "Invalid channel ${1}" "1"
            ;;
        "1" | "3")
            channel_dir="${1}"
            channel_name="$(basename "${1}")"
            ;;
        "0")
            channel_dir="$(_channel_check "${1}")"
            channel_name="${1}"
            ;;
    esac
else
    channel_dir="${script_path}/channels/${channel_name}"
fi

if (( EUID != 0 )); then
    _msg_warn "This script must be run as root." >&2
    _msg_warn "Re-run 'sudo ${0} ${ARGUMENT[*]}'"
    sudo "${0}" "${ARGUMENT[@]}" --rerun
    exit "${?}"
fi

# Check architecture for each channel
_channel_check_arch "${channel_dir}" || _msg_error "${channel_name} channel does not support current architecture (${arch})." "1"

# Set vars
build_dir="${work_dir}/build/${arch}" cache_dir="${work_dir}/cache/${arch}" isofs_dir="${build_dir}/iso" lockfile_dir="${build_dir}/lockfile" gitrev="$(cd "${script_path}"; git rev-parse --short HEAD)" preset_dir="${script_path}/presets"


# Create dir
for _dir in build_dir cache_dir isofs_dir lockfile_dir out_dir; do
    mkdir -p "$(eval "echo \$${_dir}")"
    _msg_debug "${_dir} is $(realpath "$(eval "echo \$${_dir}")")"
    eval "${_dir}=\"$(realpath "$(eval "echo \$${_dir}")")\""
done

# Set for special channels
if [[ "${channel_name}" = "clean" ]]; then
   _run_cleansh
    exit 0
fi

# Check channel version
_msg_debug "channel path is ${channel_dir}"
if ! _channel_check_version "${channel_dir}"; then
    _msg_error "This channel does not support Alter ISO 3."
    if [[ -d "${script_path}/.git" ]]; then
        _msg_error "Please run \"git checkout alteriso-2\"" "1"
    else
        _msg_error "Please download old version here.\nhttps://github.com/FascodeNet/alterlinux/releases" "1"
    fi
fi

prepare_env
prepare_build
_validate_options
_build

[[ "${cleaning}" = true ]] || true && _run_cleansh

exit

# vim:ts=4:sw=4:et:
