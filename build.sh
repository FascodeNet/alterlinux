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
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-"$(date +%s)"}"
set -E

# Internal config
# Do not change these values.
script_path="$( cd -P "$( dirname "$(readlink -f "${0}")" )" && pwd )"
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
    _msg_info "                 Plymouth:   ${boot_splash}"
    _msg_info "           Plymouth theme:   ${theme_name}"
    _msg_info "                 Language:   ${locale_name}"
    
    _build_confirm
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

    [[ "${nosigcheck}" = true ]] && sed -i "/SigLevel/d; /\[options\]/a SigLebel = Never" "${pacman_conf}"

    [[ -n "$(find "${cache_dir}" -maxdepth 1 -name '*.pkg.tar.*' 2> /dev/null)" ]] && _msg_info "Use cached package files in ${cache_dir}"

    _msg_info "Done!"
}

# Prepare working directory and copy custom root file system files.
_make_custom_airootfs() {
    local passwd=()
    local _airootfs_list=()
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
        if [[ "$(realpath -q -- "${pacstrap_dir}${filename}")" != "$(realpath -q -- "${pacstrap_dir}")"* ]]; then
            _msg_error "Failed to set permissions on '${pacstrap_dir}${filename}'. Outside of valid path." 1
        # Warn if the file does not exist
        elif [[ ! -e "${pacstrap_dir}${filename}" ]]; then
            _msg_warn "Cannot change permissions of '${pacstrap_dir}${filename}'. The file or directory does not exist."
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

    # Set up for pacman_debug
    [[ "${pacman_debug}" = true ]] && buildmode_pkg_list=("--debug" "${buildmode_pkg_list[@]}")

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

    # Remove --debug from packages list
    readarray -t buildmode_pkg_list < <(printf "%s\n" "${buildmode_pkg_list[@]}" | grep -xv -- "--debug")

    # Create a list of packages to be finally installed as packages.list directly under the working directory.
    echo -e "# The list of packages that is installed in live cd.\n#\n" > "${build_dir}/packages.list"
    printf "%s\n" "${buildmode_pkg_list[@]}" >> "${build_dir}/packages.list"

    _msg_info "Done! Packages installed successfully."
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
    _cp "${script_path}/syslinux/"* "${build_dir}/syslinux/"
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
        "${pacstrap_dir}/usr/share/edk2-shell/"* \
        "${script_path}/efiboot/${use_bootloader_type}" \
        "${pacstrap_dir}/boot/vmlinuz-"* \
        "${pacstrap_dir}/boot/initramfs-"*".img" \
        "${_available_ucodes[@]}" \
        2>/dev/null | awk 'END { print $1 }')"
    # Create a FAT image for the EFI system partition
    _make_efibootimg "$efiboot_imgsize"

    # Copy systemd-boot EFI binary to the default/fallback boot path
    local _boot
    for _boot in "${pacstrap_dir}/usr/lib/systemd/boot/efi/systemd-boot"*".efi"; do
        mcopy -i "${work_dir}/efiboot.img" "${_boot}" \
        "::/EFI/BOOT/BOOT$(basename "${_boot}" | cut -d . -f 1 | sed "s|systemd-boot||g").EFI"
    done

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
    local _shell
    if [[ -e "${pacstrap_dir}/usr/share/edk2-shell/" ]]; then
        #install -m 0644 -- "${pacstrap_dir}/usr/share/edk2-shell/x64/Shell_Full.efi" "${isofs_dir}/shellx64.efi"
        for _shell in "${pacstrap_dir}/usr/share/edk2-shell/"*; do
            [[ -e "${_shell}/Shell_Full.efi" ]] && mcopy -i "${work_dir}/efiboot.img" "${_shell}/Shell_Full.efi" "::/shell$(basename "${_shell}").efi" && continue
            [[ -e "${_shell}/Shell.efi" ]] && mcopy -i "${work_dir}/efiboot.img" "${_shell}/Shell.efi" "::/shell$(basename "${_shell}").efi"
        done
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
    local _boot
    for _boot in "${pacstrap_dir}/usr/lib/systemd/boot/efi/systemd-boot"*".efi"; do
        install -m 0644 -- "${_boot}" \
            "${isofs_dir}/EFI/BOOT/BOOT$(basename "${_boot}" | cut -d . -f 1 | sed "s|systemd-boot||g").EFI"
    done

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
    local _shell
    if [[ -e "${pacstrap_dir}/usr/share/edk2-shell/" ]]; then
        #install -m 0644 -- "${pacstrap_dir}/usr/share/edk2-shell/x64/Shell_Full.efi" "${isofs_dir}/shellx64.efi"
        for _shell in "${pacstrap_dir}/usr/share/edk2-shell/"*; do
            [[ -e "${_shell}/Shell_Full.efi" ]] && install -m 0644 -- "${_shell}/Shell_Full.efi" "${isofs_dir}/shell$(basename "${_shell}").efi" && continue
            [[ -e "${_shell}/Shell.efi" ]] && install -m 0644 -- "${_shell}/Shell.efi" "${isofs_dir}/shell$(basename "${_shell}").efi"
        done
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
    mapfile -t bootstrap_pkg_list_from_file < <("${tools_dir}/pkglist.sh" "${pkglist_args[@]}")
    bootstrap_pkg_list+=("${bootstrap_pkg_list_from_file[@]}")
    if (( ${#bootstrap_pkg_list_from_file[@]} < 1 )); then
        (( validation_error=validation_error+1 ))
        _msg_error "No package specified in '${bootstrap_packages}'." 0
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
    bsdtar -cf - "bootstrap" | pv -p |  gzip -cn9 > "${out_dir}/${image_name}"
    _msg_info "Done!"
    # checksum
    _mkimagechecksum "${out_dir}/${tar_filename}"
    _msg_info "Done! | $(ls -sh "${out_dir}/${tar_filename}")"
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

# Set defaults and, if present, overrides from mkarchiso command line option parameters
_set_overrides() {
    # Set variables that have command line overrides
    [[ ! -v override_buildmodes ]] || buildmodes=("${override_buildmodes[@]}")
    if (( ${#buildmodes[@]} < 1 )); then
        buildmodes+=('iso')
    fi
    if [[ -v override_work_dir ]]; then
        work_dir="$override_work_dir"
    elif [[ -z "$work_dir" ]]; then
        work_dir='./work'
    fi
    work_dir="$(realpath -- "$work_dir")"
    if [[ -v override_out_dir ]]; then
        out_dir="$override_out_dir"
    elif [[ -z "$out_dir" ]]; then
        out_dir='./out'
    fi
    out_dir="$(realpath -- "$out_dir")"
    if [[ -v override_pacman_conf ]]; then
        pacman_conf="$override_pacman_conf"
    elif [[ -z "$pacman_conf" ]]; then
        pacman_conf="/etc/pacman.conf"
    fi
    pacman_conf="$(realpath -- "$pacman_conf")"
    [[ ! -v override_pkg_list ]] || pkg_list+=("${override_pkg_list[@]}")
    # TODO: allow overriding bootstrap_pkg_list
    if [[ -v override_iso_label ]]; then
        iso_label="$override_iso_label"
    elif [[ -z "$iso_label" ]]; then
        iso_label="${app_name^^}"
    fi
    if [[ -v override_iso_publisher ]]; then
        iso_publisher="$override_iso_publisher"
    elif [[ -z "$iso_publisher" ]]; then
        iso_publisher="${app_name}"
    fi
    if [[ -v override_iso_application ]]; then
        iso_application="$override_iso_application"
    elif [[ -z "$iso_application" ]]; then
        iso_application="${app_name} iso"
    fi
    if [[ -v override_install_dir ]]; then
        install_dir="$override_install_dir"
    elif [[ -z "$install_dir" ]]; then
        install_dir="${app_name}"
    fi
    [[ ! -v override_gpg_key ]] || gpg_key="$override_gpg_key"
    [[ ! -v override_gpg_sender ]] || gpg_sender="$override_gpg_sender"
    if [[ -v override_cert_list ]]; then
        sign_netboot_artifacts="y"
    fi
    [[ ! -v override_cert_list ]] || cert_list+=("${override_cert_list[@]}")
    if [[ -v override_quiet ]]; then
        quiet="$override_quiet"
    elif [[ -z "$quiet" ]]; then
        quiet="y"
    fi

    # Set variables that do not have overrides
    [[ -n "$arch" ]] || arch="$(uname -m)"
    [[ -n "$airootfs_image_type" ]] || airootfs_image_type="squashfs"
    [[ -n "$iso_name" ]] || iso_name="${app_name}"
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
    # Set the package list to use
    local buildmode_pkg_list=("${pkg_list[@]}")
    pacstrap_dir="${build_dir}/airootfs"

    # Create working directory
    [[ -d "${pacstrap_dir}" ]] || install -d -- "${pacstrap_dir}"
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
    _run_once _make_alteriso_info
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
    #pacstrap_dir="${work_dir}/${arch}/bootstrap/root.${arch}"
    pacstrap_dir="${build_dir}/bootstrap"

    [[ -d "${work_dir}" ]] || install -d -- "${work_dir}"
    install -d -m 0755 -o 0 -g 0 -- "${pacstrap_dir}"

    [[ "${quiet}" == "y" ]] || _show_config
    _run_once _make_basefs
    _run_once _make_pacman_conf
    _run_once _make_packages
    [[ "${noaur}" = false ]] && _run_once _make_aur
    [[ "${nopkgbuild}" = false ]] && _run_once _make_pkgbuild
    _run_once _make_custom_airootfs
    _run_once _make_version
    _run_once _make_customize_airootfs
    _run_once _make_customize_bootstrap
    _run_once _make_pkglist
    _run_once _cleanup_pacstrap_dir
    _run_once _build_bootstrap_image

    remove "${pacstrap_dir}.img"
    mv "${pacstrap_dir}.img.org" "${pacstrap_dir}.img"
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
_msg_debug "Channel check status is $(_channel_check "${1}" >/dev/null ; printf "%d" "${?}")"
if [[ -n "${1+SET}" ]]; then
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

# Check root.
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
