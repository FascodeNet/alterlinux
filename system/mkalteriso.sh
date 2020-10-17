#!/usr/bin/env bash
#
# mkalteriso
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2020 Fascode Network.
#

set -e -u

# Control the environment
umask 0022
export LANG="C"
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-"$(date +%s)"}"

app_name="${0##*/}"
arch="$(uname -m)"
pkg_list=""
run_cmd=""
quiet="n"
pacman_conf="/etc/pacman.conf"
export iso_label="ALTER_$(date +%Y%m)"
iso_publisher='Fascode Network <https://fascode.net>'
iso_application="Alter Linux Live/Rescue CD"
install_dir="alter"
work_dir="work"
out_dir="out"
sfs_mode="sfs"
sfs_comp="zstd"
sfs_comp_opt=""
gpg_key=""

# Show an INFO message
# $1: message string
_msg_info() {
    local _msg="${1}"
    [[ "${quiet}" == "y" ]] || printf '[%s] INFO: %s\n' "${app_name}" "${_msg}"
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
_msg_error() {
    local _msg="${1}"
    local _error=${2}
    printf '\n[%s] ERROR: %s\n\n' "${app_name}" "${_msg}" >&2
    if (( _error > 0 )); then
        exit ${_error}
    fi
}

cdback() {
    cd - > /dev/null
}

_chroot_init() {
    mkdir -p -- "${work_dir}/airootfs"

    #_pacman "base base-devel syslinux" <- old code

    _pacman "base"
}

# Unmount chroot dir
_umount_chroot () {
    local mount
    for mount in $(mount | awk '{print $3}' | grep $(realpath "${work_dir}/airootfs") | tac); do
        _msg_info "Unmounting ${mount}"
        umount -lf "${mount}"
    done
}

_chroot_run() {
    _umount_chroot
    eval -- arch-chroot "${work_dir}/airootfs" "${run_cmd}"
    _umount_chroot
}

_mount_airootfs() {
    trap "_umount_airootfs" EXIT HUP INT TERM
    mkdir -p -- "${work_dir}/mnt/airootfs"
    _msg_info "Mounting '${work_dir}/airootfs.img' on '${work_dir}/mnt/airootfs'"
    mount -- "${work_dir}/airootfs.img" "${work_dir}/mnt/airootfs"
    _msg_info "Done!"
}

_umount_airootfs() {
    _msg_info "Unmounting '${work_dir}/mnt/airootfs'"
    umount -d -- "${work_dir}/mnt/airootfs"
    _msg_info "Done!"
    rmdir -- "${work_dir}/mnt/airootfs"
    trap - EXIT HUP INT TERM
}

# Show help usage, with an exit status.
# $1: exit status number.
_usage ()
{
    echo "usage ${app_name} [options] command <command options>"
    echo " general options:"
    echo "    -a Architecture  Set architecture."
    echo "    -p PACKAGE(S)    Package(s) to install, can be used multiple times"
    echo "    -r <command>     Run <command> inside airootfs"
    echo "    -C <file>        Config file for pacman."
    echo "                     Default: '${pacman_conf}'"
    echo "                     Default: '${install_dir}'"
    echo "                     NOTE: Max 8 characters, use only [a-z0-9]"
    echo "    -w <work_dir>    Set the working directory"
    echo "                     Default: '${work_dir}'"
    echo "    -o <out_dir>     Set the output directory"
    echo "                     Default: '${out_dir}'"
    echo "    -s <sfs_mode>    Set SquashFS image mode (img or sfs)"
    echo "                     img: prepare airootfs.sfs for dm-snapshot usage"
    echo "                     sfs: prepare airootfs.sfs for overlayfs usage"
    echo "                     Default: ${sfs_mode}"
    echo "    -c <comp_type>   Set SquashFS compression type (gzip, lzma, lzo, xz, zstd)"
    echo "                     Default: '${sfs_comp}'"
    echo "    -t <options>     Set compressor-specific options. Run 'mksquashfs -h' for more help."
    echo "                     Default: empty"
    # Verbose output is forced on.
    # echo "    -v               Enable verbose output"
    echo "    -h               This message"
    echo " commands:"
    echo "   init"
    echo "      Make base layout and install base group"
    echo "   install"
    echo "      Install all specified packages (-p)"
    echo "   install_file"
    echo "      Install all specified packages from a package file (-p)"
    echo "   run"
    echo "      run command specified by -r"
    echo "   prepare"
    echo "      build all images"
    echo "   pkglist"
    echo "      make a pkglist.txt of packages installed on airootfs"
    echo "   iso <image name>"
    echo "      build an iso image from the working dir"
    echo "   tarball <file name>"
    echo "      Build a tarball from the working dir."
    exit ${1}
}

# Shows configuration according to command mode.
# $1: init | install | run | prepare | iso
_show_config () {
    local _mode="$1"
    echo
    _msg_info "Configuration settings"
    _msg_info "                  Command:   ${command_name}"
    _msg_info "             Architecture:   ${arch}"
    _msg_info "        Working directory:   ${work_dir}"
    _msg_info "   Installation directory:   ${install_dir}"
    case "${_mode}" in
        init)
            _msg_info "       Pacman config file:   ${pacman_conf}"
            ;;
        install)
            _msg_info "       Pacman config file:   ${pacman_conf}"
            _msg_info "                 Packages:   ${pkg_list}"
            ;;
        run)
            _msg_info "              Run command:   ${run_cmd}"
            ;;
        prepare)
            _msg_info "SquashFS compression type:   ${sfs_comp}"
            if [[ -n "${sfs_comp_opt}" ]]; then
                _msg_info "Squashfs compression opts:    ${sfs_comp_opt}"
            fi
            ;;
        pkglist)
            ;;
        iso)
            _msg_info "               Image name:   ${img_name}"
            _msg_info "               Disk label:   ${iso_label}"
            _msg_info "           Disk publisher:   ${iso_publisher}"
            _msg_info "         Disk application:   ${iso_application}"
            ;;
    esac
    echo
}

# Install desired packages to airootfs
_pacman ()
{
    _msg_info "Installing packages to '${work_dir}/airootfs/'..."

    if [[ "${quiet}" = "y" ]]; then
        pacstrap -C "${pacman_conf}" -c -G -M -- "${work_dir}/airootfs" $* &> /dev/null
    else
        pacstrap -C "${pacman_conf}" -c -G -M -- "${work_dir}/airootfs" $*
    fi

    _msg_info "Packages installed successfully!"
}

# Install desired packages to airootfs from pkg file
_pacman_file ()
{
    _msg_info "Installing packages to '${work_dir}/airootfs/'..."

    if [[ "${quiet}" = "y" ]]; then
        pacstrap -C "${pacman_conf}" -c -G -M -U "${work_dir}/airootfs" $* &> /dev/null
    else
        pacstrap -C "${pacman_conf}" -c -G -M -U "${work_dir}/airootfs" $*
    fi

    _msg_info "Packages installed successfully!"
}


_cleanup_common () {
    # Delete pacman database sync cache files (*.tar.gz)
    if [[ -d "${work_dir}/airootfs/var/lib/pacman" ]]; then
        find "${work_dir}/airootfs/var/lib/pacman" -maxdepth 1 -type f -delete
    fi
    # Delete pacman database sync cache
    if [[ -d "${work_dir}/airootfs/var/lib/pacman/sync" ]]; then
        find "${work_dir}/airootfs/var/lib/pacman/sync" -delete
    fi
    # Delete pacman package cache
    if [[ -d "${work_dir}/airootfs/var/cache/pacman/pkg" ]]; then
        find "${work_dir}/airootfs/var/cache/pacman/pkg" -type f -delete
    fi
    # Delete all log files, keeps empty dirs.
    if [[ -d "${work_dir}/airootfs/var/log" ]]; then
        find "${work_dir}/airootfs/var/log" -type f -delete
    fi
    # Delete all temporary files and dirs
    if [[ -d "${work_dir}/airootfs/var/tmp" ]]; then
        find "${work_dir}/airootfs/var/tmp" -mindepth 1 -delete
    fi
    # Delete package pacman related files.
    find "${work_dir}" \( -name '*.pacnew' -o -name '*.pacsave' -o -name '*.pacorig' \) -delete
}

# Cleanup airootfs
_cleanup () {
    _msg_info "Cleaning up what we can on airootfs..."

    _cleanup_common

    # Delete initcpio image(s)
    if [[ -d "${work_dir}/airootfs/boot" ]]; then
        find "${work_dir}/airootfs/boot" -type f -name '*.img' -delete
    fi
    # Delete kernel(s)
    if [[ -d "${work_dir}/airootfs/boot" ]]; then
        find "${work_dir}/airootfs/boot" -type f -name 'vmlinuz*' -delete
    fi

    _msg_info "Done!"
}

# Cleanup airootfs
_cleanup_tarball () {
    _msg_info "Cleaning up what we can on airootfs for tarball..."
    _cleanup_common
    _msg_info "Done!"
}

# Makes a ext4 filesystem inside a SquashFS from a source directory.
_mkairootfs_img () {
    if [[ ! -e "${work_dir}/airootfs" ]]; then
        _msg_error "The path '${work_dir}/airootfs' does not exist" 1
    fi

    _msg_info "Creating ext4 image of 32GiB..."
    truncate -s 32G -- "${work_dir}/airootfs.img"
    if [[ ${quiet} = "y" ]]; then
        mkfs.ext4 -q -O '^has_journal,^resize_inode' -E 'lazy_itable_init=0' -m 0 -F -- "${work_dir}/airootfs.img"
    else
        mkfs.ext4 -O '^has_journal,^resize_inode' -E 'lazy_itable_init=0' -m 0 -F -- "${work_dir}/airootfs.img"
    fi
    tune2fs -c 0 -i 0 -- "${work_dir}/airootfs.img" &> /dev/null
    _msg_info "Done!"
    _mount_airootfs
    _msg_info "Copying '${work_dir}/airootfs/' to '${work_dir}/mnt/airootfs/'..."
    cp -aT -- "${work_dir}/airootfs/" "${work_dir}/mnt/airootfs/"
    chown root:root -- "${work_dir}/mnt/airootfs/"
    _msg_info "Done!"
    _umount_airootfs
    mkdir -p -- "${work_dir}/iso/${install_dir}/${arch}"
    _msg_info "Creating SquashFS image, this may take some time..."
    if [[ "${quiet}" = "y" ]]; then
        mksquashfs "${work_dir}/airootfs.img" "${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs" -noappend -no-progress -comp "${sfs_comp}" ${sfs_comp_opt} &> /dev/null
    else
        mksquashfs "${work_dir}/airootfs.img" "${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs" -noappend -comp "${sfs_comp}" ${sfs_comp_opt}
    fi
    _msg_info "Done!"
    rm -- "${work_dir}/airootfs.img"
}

# Makes a SquashFS filesystem from a source directory.
_mkairootfs_sfs () {
    if [[ ! -e "${work_dir}/airootfs" ]]; then
        _msg_error "The path '${work_dir}/airootfs' does not exist" 1
    fi

    mkdir -p -- "${work_dir}/iso/${install_dir}/${arch}"
    _msg_info "Creating SquashFS image, this may take some time..."
    if [[ "${quiet}" = "y" ]]; then
        mksquashfs "${work_dir}/airootfs" "${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs" -noappend -comp -no-progress "${sfs_comp}" ${sfs_comp_opt}  &> /dev/null
    else
        mksquashfs "${work_dir}/airootfs" "${work_dir}/iso/${install_dir}/${arch}/airootfs.sfs" -noappend -comp "${sfs_comp}" ${sfs_comp_opt}
    fi
    _msg_info "Done!"
}

_mkchecksum () {
    _msg_info "Creating checksum file for self-test..."
    cd -- "${work_dir}/iso/${install_dir}/${arch}"
    sha512sum airootfs.sfs > airootfs.sha512
    cdback
    _msg_info "Done!"
}

_checksum_common() {
    local name="${1}"
    _msg_info "Creating md5 checksum ..."
    cd -- "${out_dir}"
    md5sum "${name}" > "${name}.md5"
    cdback
    # _msg_info "Done!"


    _msg_info "Creating sha256 checksum ..."
    cd -- "${out_dir}"
    sha256sum "${name}" > "${name}.sha256"
    cdback
    # _msg_info "Done!"
}

_mkisochecksum() {
    _checksum_common "${img_name}"
}

_mktarchecksum() {
    _checksum_common "${tarball_name}"
}

_mksignature () {
    _msg_info "Creating signature file..."
    cd -- "${work_dir}/iso/${install_dir}/${arch}"
    gpg --detach-sign --default-key ${gpg_key} airootfs.sfs
    cd -- "${OLDPWD}"
    _msg_info "Done!"
}

command_pkglist () {
    _show_config pkglist

    _msg_info "Creating a list of installed packages on live-enviroment..."
    pacman -Q --sysroot "${work_dir}/airootfs" > "${work_dir}/iso/${install_dir}/pkglist.${arch}.txt"
    _msg_info "Done!"

}

# Create an ISO9660 filesystem from "iso" directory.
command_iso () {
    local _iso_efi_boot_args=""

    if [[ ! -f "${work_dir}/iso/isolinux/isolinux.bin" ]]; then
         _msg_error "The file '${work_dir}/iso/isolinux/isolinux.bin' does not exist." 1
    fi
    if [[ ! -f "${work_dir}/iso/isolinux/isohdpfx.bin" ]]; then
         _msg_error "The file '${work_dir}/iso/isolinux/isohdpfx.bin' does not exist." 1
    fi

    # If exists, add an EFI "El Torito" boot image (FAT filesystem) to ISO-9660 image.
    if [[ -f "${work_dir}/iso/EFI/alteriso/efiboot.img" ]]; then
        _iso_efi_boot_args="-eltorito-alt-boot
                            -e EFI/alteriso/efiboot.img
                            -no-emul-boot
                            -isohybrid-gpt-basdat"
    fi

    _show_config iso

    mkdir -p -- "${out_dir}"
    _msg_info "Creating ISO image..."
    local _qflag=""
    if [[ "${quiet}" = "y" ]]; then
        _qflag="-quiet"
    fi
    xorriso -as mkisofs ${_qflag} \
        -iso-level 3 \
        -full-iso9660-filenames \
        -joliet \
        -joliet-long \
        -rational-rock \
        -volid "${iso_label}" \
        -appid "${iso_application}" \
        -publisher "${iso_publisher}" \
        -preparer "prepared by mkalteriso" \
        -eltorito-boot isolinux/isolinux.bin \
        -eltorito-catalog isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -isohybrid-mbr ${work_dir}/iso/isolinux/isohdpfx.bin \
        ${_iso_efi_boot_args} \
        -output "${out_dir}/${img_name}" \
        "${work_dir}/iso/"
    _mkisochecksum
    _msg_info "Done! | $(ls -sh -- "${out_dir}/${img_name}")"
}

# # Compress tarball from "iso" directory.
command_tarball () {
    if [[ ! -e "${work_dir}/airootfs" ]]; then
        _msg_error "The path '${work_dir}/airootfs' does not exist" 1
    fi

    _cleanup_tarball

    mkdir -p "${out_dir}"
    _msg_info "Creating tarball..."

    local _vflag=""
    if [[ "${quiet}" = "n" ]]; then
        _vflag="-v"
    fi

    local tar_path="$(realpath ${out_dir})/${tarball_name}"

    cd "${work_dir}/airootfs"

    tar -J -p -c ${_vflag} -f "${tar_path}" ./*

    cdback

    _mktarchecksum
    _msg_info "Done! | $(ls -sh ${tar_path})"
}

# create airootfs.sfs filesystem, and push it in "iso" directory.
command_prepare () {
    _show_config prepare

    _cleanup
    if [[ "${sfs_mode}" = "sfs" ]]; then
        _mkairootfs_sfs
    else
        _mkairootfs_img
    fi
    _mkchecksum
    if [[ ${gpg_key} ]]; then
      _mksignature
    fi
}

# Install packages on airootfs.
# A basic check to avoid double execution/reinstallation is done via hashing package names.
command_install () {
    if [[ ! -f "${pacman_conf}" ]]; then
        _msg_error "Pacman config file '${pacman_conf}' does not exist" 1
    fi

    #trim spaces
    pkg_list="$(echo ${pkg_list})"

    if [[ -z "${pkg_list}" ]]; then
        _msg_error "Packages must be specified" 0
        _usage 1
    fi

    _show_config install

    _pacman "${pkg_list}"
}

# Install packages on airootfs from pkg file
# A basic check to avoid double execution/reinstallation is done via hashing package names.
command_install_file () {
    if [[ ! -f "${pacman_conf}" ]]; then
        _msg_error "Pacman config file '${pacman_conf}' does not exist" 1
    fi

    #trim spaces
    pkg_list="$(echo ${pkg_list})"

    if [[ -z ${pkg_list} ]]; then
        _msg_error "Packages must be specified" 0
        _usage 1
    fi

    _show_config install

    _pacman_file "${pkg_list}"
}

command_init() {
    _show_config init
    _chroot_init
}

command_run() {
    _show_config run
    _chroot_run
}

while getopts 'a:p:r:C:L:P:A:D:w:o:s:c:g:t:vhx' arg; do
    case "${arg}" in
        a) arch="${OPTARG}" ;;
        p) pkg_list="${pkg_list} ${OPTARG}" ;;
        r) run_cmd="${OPTARG}" ;;
        C) pacman_conf="$(realpath -- "${OPTARG}")" ;;
        L) iso_label="${OPTARG}" ;;
        P) iso_publisher="${OPTARG}" ;;
        A) iso_application="${OPTARG}" ;;
        D) install_dir="${OPTARG}" ;;
        w) work_dir="$(realpath -- "${OPTARG}")" ;;
        o) out_dir="$(realpath -- "${OPTARG}")" ;;
        s) sfs_mode="${OPTARG}" ;;
        c) sfs_comp="${OPTARG}" ;;
        t) sfs_comp_opt="${OPTARG}" ;;
        g) gpg_key="${OPTARG}" ;;
        v) quiet="n" ;;
        x) set -xv ;;
        h|?) _usage 0 ;;
        *)
            _msg_error "Invalid argument '${arg}'" 0
            _usage 1
            ;;
    esac
done

if (( EUID != 0 )); then
    _msg_error "${app_name} must be run as root." 1
fi

shift $((OPTIND - 1))

if (( $# < 1 )); then
    _msg_error "No command specified" 0
    _usage 1
fi
command_name="${1}"

case "${command_name}" in
    init)
        command_init
        ;;
    install)
        command_install
        ;;
    install_file)
        command_install_file
        ;;
    run)
        command_run
        ;;
    prepare)
        command_prepare
        ;;
    pkglist)
        command_pkglist
        ;;
    iso)
        if (( $# < 2 )); then
            _msg_error "No image specified" 0
            _usage 1
        fi
        img_name="${2}"
        command_iso
        ;;
    tarball)
        if [[ $# -lt 2 ]]; then
            _msg_error "No name specified" 0
            _usage 1
        fi
        tarball_name="${2}"
        command_tarball
        ;;
    *)
        _msg_error "Invalid command name '${command_name}'" 0
        _usage 1
        ;;
esac

# vim:ts=4:sw=4:et:
