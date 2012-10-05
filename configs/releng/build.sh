#!/bin/bash

set -e -u

iso_name=archlinux
iso_label="ARCH_$(date +%Y%m)"
iso_version=$(date +%Y.%m.%d)
install_dir=arch
arch=$(uname -m)
work_dir=work
out_dir=out
verbose=""
cmd_args=""

script_path=$(readlink -f ${0%/*})

setup_workdir() {
    cache_dirs=($(pacman -v 2>&1 | grep '^Cache Dirs:' | sed 's/Cache Dirs:\s*//g'))
    mkdir -p "${work_dir}"
    pacman_conf="${work_dir}/pacman.conf"
    sed -r "s|^#?\\s*CacheDir.+|CacheDir = $(echo -n ${cache_dirs[@]})|g" \
        "${script_path}/pacman.conf" > "${pacman_conf}"
}

# Base installation (root-image)
make_basefs() {
    mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" init
    mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" -p "memtest86+ mkinitcpio-nfs-utils nbd curl" install

    # Install systemd-sysvcompat in this way until hits {base} group
    mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" \
        -r 'pacman -R --noconfirm --noprogressbar initscripts sysvinit' \
        run
    mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" \
        -p "systemd-sysvcompat" \
        install
}

# Additional packages (root-image)
make_packages() {
    mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" -p "$(grep -v ^# ${script_path}/packages.${arch})" install
}

# Copy mkinitcpio archiso hooks (root-image)
make_setup_mkinitcpio() {
   if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        local _hook
        for _hook in archiso archiso_shutdown archiso_pxe_common archiso_pxe_nbd archiso_pxe_http archiso_pxe_nfs archiso_loop_mnt; do
            cp /usr/lib/initcpio/hooks/${_hook} ${work_dir}/root-image/usr/lib/initcpio/hooks
            cp /usr/lib/initcpio/install/${_hook} ${work_dir}/root-image/usr/lib/initcpio/install
        done
        cp /usr/lib/initcpio/install/archiso_kms ${work_dir}/root-image/usr/lib/initcpio/install
        cp /usr/lib/initcpio/archiso_shutdown ${work_dir}/root-image/usr/lib/initcpio
        cp ${script_path}/mkinitcpio.conf ${work_dir}/root-image/etc/mkinitcpio-archiso.conf
        : > ${work_dir}/build.${FUNCNAME}
   fi
}

# Prepare ${install_dir}/boot/
make_boot() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        local _src=${work_dir}/root-image
        local _dst_boot=${work_dir}/iso/${install_dir}/boot
        mkdir -p ${_dst_boot}/${arch}
        mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" \
            -r 'mkinitcpio -c /etc/mkinitcpio-archiso.conf -k /boot/vmlinuz-linux -g /boot/archiso.img' \
            run
        mv ${_src}/boot/archiso.img ${_dst_boot}/${arch}/archiso.img
        mv ${_src}/boot/vmlinuz-linux ${_dst_boot}/${arch}/vmlinuz
        cp ${_src}/boot/memtest86+/memtest.bin ${_dst_boot}/memtest
        cp ${_src}/usr/share/licenses/common/GPL2/license.txt ${_dst_boot}/memtest.COPYING
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

make_efi() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        if [[ ${arch} == "x86_64" ]]; then

            mkdir -p ${work_dir}/iso/EFI/boot
            cp ${work_dir}/root-image/usr/lib/gummiboot/gummibootx64.efi ${work_dir}/iso/EFI/boot/bootx64.efi

            mkdir -p ${work_dir}/iso/loader/entries
            cp ${script_path}/efiboot/loader/loader.conf ${work_dir}/iso/loader/
            cp ${script_path}/efiboot/loader/entries/uefi-shell-v2-x86_64.conf ${work_dir}/iso/loader/entries/
            cp ${script_path}/efiboot/loader/entries/uefi-shell-v1-x86_64.conf ${work_dir}/iso/loader/entries/

            sed "s|%ARCHISO_LABEL%|${iso_label}|g;
                 s|%INSTALL_DIR%|${install_dir}|g" ${script_path}/efiboot/loader/entries/archiso-x86_64-usb.conf > ${work_dir}/iso/loader/entries/archiso-x86_64.conf

            # EFI Shell 2.0 for UEFI 2.3+ ( http://sourceforge.net/apps/mediawiki/tianocore/index.php?title=UEFI_Shell )
            wget -O ${work_dir}/iso/EFI/shellx64_v2.efi https://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2/ShellBinPkg/UefiShell/X64/Shell.efi
            # EFI Shell 1.0 for non UEFI 2.3+ ( http://sourceforge.net/apps/mediawiki/tianocore/index.php?title=Efi-shell )
            wget -O ${work_dir}/iso/EFI/shellx64_v1.efi https://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2/EdkShellBinPkg/FullShell/X64/Shell_Full.efi

        fi
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

make_efiboot() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        if [[ ${arch} == "x86_64" ]]; then

            mkdir -p ${work_dir}/iso/EFI/archiso
            truncate -s 31M ${work_dir}/iso/EFI/archiso/efiboot.img
            mkfs.vfat -n ARCHISO_EFI ${work_dir}/iso/EFI/archiso/efiboot.img

            mkdir -p ${work_dir}/efiboot
            mount ${work_dir}/iso/EFI/archiso/efiboot.img ${work_dir}/efiboot

            mkdir -p ${work_dir}/efiboot/EFI/archiso
            cp ${work_dir}/iso/${install_dir}/boot/x86_64/vmlinuz ${work_dir}/efiboot/EFI/archiso/vmlinuz.efi
            cp ${work_dir}/iso/${install_dir}/boot/x86_64/archiso.img ${work_dir}/efiboot/EFI/archiso/archiso.img

            mkdir -p ${work_dir}/efiboot/EFI/boot
            cp ${work_dir}/root-image/usr/lib/gummiboot/gummibootx64.efi ${work_dir}/efiboot/EFI/boot/bootx64.efi

            mkdir -p ${work_dir}/efiboot/loader/entries
            cp ${script_path}/efiboot/loader/loader.conf ${work_dir}/efiboot/loader/
            cp ${script_path}/efiboot/loader/entries/uefi-shell-v2-x86_64.conf ${work_dir}/efiboot/loader/entries/
            cp ${script_path}/efiboot/loader/entries/uefi-shell-v1-x86_64.conf ${work_dir}/efiboot/loader/entries/

            sed "s|%ARCHISO_LABEL%|${iso_label}|g;
                 s|%INSTALL_DIR%|${install_dir}|g" ${script_path}/efiboot/loader/entries/archiso-x86_64-cd.conf > ${work_dir}/efiboot/loader/entries/archiso-x86_64.conf

            cp ${work_dir}/iso/EFI/shellx64_v2.efi ${work_dir}/efiboot/EFI/
            cp ${work_dir}/iso/EFI/shellx64_v1.efi ${work_dir}/efiboot/EFI/

            umount ${work_dir}/efiboot

        fi
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Prepare /${install_dir}/boot/syslinux
make_syslinux() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        local _src_syslinux=${work_dir}/root-image/usr/lib/syslinux
        local _dst_syslinux=${work_dir}/iso/${install_dir}/boot/syslinux
        mkdir -p ${_dst_syslinux}
        for _cfg in ${script_path}/syslinux/*.cfg; do
            sed "s|%ARCHISO_LABEL%|${iso_label}|g;
                 s|%INSTALL_DIR%|${install_dir}|g;
                 s|%ARCH%|${arch}|g" ${_cfg} > ${_dst_syslinux}/${_cfg##*/}
        done
        cp ${script_path}/syslinux/splash.png ${_dst_syslinux}
        cp ${_src_syslinux}/*.c32 ${_dst_syslinux}
        cp ${_src_syslinux}/*.com ${_dst_syslinux}
        cp ${_src_syslinux}/*.0 ${_dst_syslinux}
        cp ${_src_syslinux}/memdisk ${_dst_syslinux}
        mkdir -p ${_dst_syslinux}/hdt
        cat ${work_dir}/root-image/usr/share/hwdata/pci.ids | gzip -9 > ${_dst_syslinux}/hdt/pciids.gz
        cat ${work_dir}/root-image/usr/lib/modules/*-ARCH/modules.alias | gzip -9 > ${_dst_syslinux}/hdt/modalias.gz
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Prepare /isolinux
make_isolinux() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        mkdir -p ${work_dir}/iso/isolinux
        sed "s|%INSTALL_DIR%|${install_dir}|g" ${script_path}/isolinux/isolinux.cfg > ${work_dir}/iso/isolinux/isolinux.cfg
        cp ${work_dir}/root-image/usr/lib/syslinux/isolinux.bin ${work_dir}/iso/isolinux/
        cp ${work_dir}/root-image/usr/lib/syslinux/isohdpfx.bin ${work_dir}/iso/isolinux/
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Customize installation (root-image)
make_customize_root_image() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        cp -af ${script_path}/root-image ${work_dir}
        cp -aT ${work_dir}/root-image/etc/skel/ ${work_dir}/root-image/root/
        ln -sf /usr/share/zoneinfo/UTC ${work_dir}/root-image/etc/localtime
        chmod 750 ${work_dir}/root-image/etc/sudoers.d
        chmod 440 ${work_dir}/root-image/etc/sudoers.d/g_wheel
        mkdir -p ${work_dir}/root-image/etc/pacman.d
        wget -O ${work_dir}/root-image/etc/pacman.d/mirrorlist 'https://www.archlinux.org/mirrorlist/?country=all&protocol=http&use_mirror_status=on'
        lynx -dump -nolist 'https://wiki.archlinux.org/index.php/Installation_Guide?action=render' >> ${work_dir}/root-image/root/install.txt
        sed -i "s/#Server/Server/g" ${work_dir}/root-image/etc/pacman.d/mirrorlist
        patch ${work_dir}/root-image/usr/bin/pacman-key < ${script_path}/pacman-key-4.0.3_unattended-keyring-init.patch
        sed -i 's/#\(en_US\.UTF-8\)/\1/' ${work_dir}/root-image/etc/locale.gen
        sed 's#\(^ExecStart=-/sbin/agetty\)#\1 --autologin root#' \
            ${work_dir}/root-image/usr/lib/systemd/system/getty@.service > ${work_dir}/root-image/etc/systemd/system/autologin@.service
        mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" \
            -r 'locale-gen' \
            run
        mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" \
            -r 'usermod -s /bin/zsh root' \
            run
        mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" \
            -r 'useradd -m -p "" -g users -G "audio,disk,optical,wheel" -s /bin/zsh arch' \
            run
        mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" \
            -r 'systemctl -f enable multi-user.target haveged.service pacman-init.service autologin@.service dhcpcd@.service || true' \
            run
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Split out /usr/lib/modules from root-image (makes more "dual-iso" friendly)
make_usr_lib_modules() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        mv ${work_dir}/root-image/usr/lib/modules ${work_dir}/usr-lib-modules
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Split out /usr/share from root-image (makes more "dual-iso" friendly)
make_usr_share() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        mv ${work_dir}/root-image/usr/share ${work_dir}/usr-share
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Process aitab
make_aitab() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        sed "s|%ARCH%|${arch}|g" ${script_path}/aitab > ${work_dir}/iso/${install_dir}/aitab
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Build all filesystem images specified in aitab (.fs .fs.sfs .sfs)
make_prepare() {
    mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" pkglist
    mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" prepare
}

# Build ISO
make_iso() {
    mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" checksum
    mkarchiso ${verbose} -w "${work_dir}" -C "${pacman_conf}" -D "${install_dir}" -L "${iso_label}" -o "${out_dir}" iso "${iso_name}-${iso_version}-${arch}.iso"
}

# Build dual-iso images from ${work_dir}/i686/iso and ${work_dir}/x86_64/iso
make_dual() {
    if [[ ! -e ${work_dir}/dual/build.${FUNCNAME} ]]; then
        if [[ ! -d ${work_dir}/i686/iso || ! -d ${work_dir}/x86_64/iso ]]; then
            echo "ERROR: i686 or x86_64 builds does not exist."
            _usage 1
        fi
        local _src_one _src_two _cfg
        if [[ ${arch} == "i686" ]]; then
            _src_one=${work_dir}/i686/iso
            _src_two=${work_dir}/x86_64/iso
        else
            _src_one=${work_dir}/x86_64/iso
            _src_two=${work_dir}/i686/iso
        fi
        mkdir -p ${work_dir}/dual/iso
        cp -a -l -f ${_src_one} ${work_dir}/dual
        cp -a -l -n ${_src_two} ${work_dir}/dual
        rm -f ${work_dir}/dual/iso/${install_dir}/aitab
        rm -f ${work_dir}/dual/iso/${install_dir}/boot/syslinux/*.cfg
        paste -d"\n" <(sed "s|%ARCH%|i686|g" ${script_path}/aitab) \
                     <(sed "s|%ARCH%|x86_64|g" ${script_path}/aitab) | uniq > ${work_dir}/dual/iso/${install_dir}/aitab
        for _cfg in ${script_path}/syslinux.dual/*.cfg; do
            sed "s|%ARCHISO_LABEL%|${iso_label}|g;
                 s|%INSTALL_DIR%|${install_dir}|g" ${_cfg} > ${work_dir}/dual/iso/${install_dir}/boot/syslinux/${_cfg##*/}
        done
        mkarchiso ${verbose} -w "${work_dir}/dual" -D "${install_dir}" checksum
        mkarchiso ${verbose} -w "${work_dir}/dual" -D "${install_dir}" -L "${iso_label}" -o "${out_dir}" iso "${iso_name}-${iso_version}-dual.iso"
        : > ${work_dir}/dual/build.${FUNCNAME}
    fi
}

purge_single ()
{
    if [[ -d ${work_dir} ]]; then
        find ${work_dir} -mindepth 1 -maxdepth 1 \
            ! -path ${work_dir}/iso -prune \
            | xargs rm -rf
    fi
}

purge_dual ()
{
    if [[ -d ${work_dir}/dual ]]; then
        find ${work_dir}/dual -mindepth 1 -maxdepth 1 \
            ! -path ${work_dir}/dual/iso -prune \
            | xargs rm -rf
    fi
}

clean_single ()
{
    rm -rf ${work_dir}
    rm -f ${out_dir}/${iso_name}-${iso_version}-*-${arch}.iso
}

clean_dual ()
{
    rm -rf ${work_dir}/dual
    rm -f ${out_dir}/${iso_name}-${iso_version}-*-dual.iso
}

make_common_single() {
    make_basefs
    make_packages
    make_setup_mkinitcpio
    make_boot
    make_efi
    make_efiboot
    make_syslinux
    make_isolinux
    make_customize_root_image
    make_usr_lib_modules
    make_usr_share
    make_aitab
    make_prepare
    make_iso
}

_usage ()
{
    echo "usage ${0} [options] command <command options>"
    echo
    echo " General options:"
    echo "    -N <iso_name>      Set an iso filename (prefix)"
    echo "                        Default: ${iso_name}"
    echo "    -V <iso_version>   Set an iso version (in filename)"
    echo "                        Default: ${iso_version}"
    echo "    -L <iso_label>     Set an iso label (disk label)"
    echo "                        Default: ${iso_label}"
    echo "    -D <install_dir>   Set an install_dir (directory inside iso)"
    echo "                        Default: ${install_dir}"
    echo "    -w <work_dir>      Set the working directory"
    echo "                        Default: ${work_dir}"
    echo "    -o <out_dir>       Set the output directory"
    echo "                        Default: ${out_dir}"
    echo "    -v                 Enable verbose output"
    echo "    -h                 This help message"
    echo
    echo " Commands:"
    echo "   build <mode>"
    echo "      Build selected .iso by <mode>"
    echo "   purge <mode>"
    echo "      Clean working directory except iso/ directory of build <mode>"
    echo "   clean <mode>"
    echo "      Clean working directory and .iso file in output directory of build <mode>"
    echo
    echo " Command options:"
    echo "         <mode> Valid values 'single', 'dual' or 'all'"
    exit ${1}
}

if [[ ${EUID} -ne 0 ]]; then
    echo "This script must be run as root."
    _usage 1
fi

while getopts 'N:V:L:D:w:o:vh' arg; do
    case "${arg}" in
        N)
            iso_name="${OPTARG}"
            cmd_args+=" -N ${iso_name}"
            ;;
        V)
            iso_version="${OPTARG}"
            cmd_args+=" -V ${iso_version}"
            ;;
        L)
            iso_label="${OPTARG}"
            cmd_args+=" -L ${iso_label}"
            ;;
        D)
            install_dir="${OPTARG}"
            cmd_args+=" -D ${install_dir}"
            ;;
        w)
            work_dir="${OPTARG}"
            cmd_args+=" -w ${work_dir}"
            ;;
        o)
            out_dir="${OPTARG}"
            cmd_args+=" -o ${out_dir}"
            ;;
        v)
            verbose="-v"
            cmd_args+=" -v"
            ;;
        h|?) _usage 0 ;;
        *)
            _msg_error "Invalid argument '${arg}'" 0
            _usage 1
            ;;
    esac
done

shift $((OPTIND - 1))

if [[ $# -lt 1 ]]; then
    echo "No command specified"
    _usage 1
fi
command_name="${1}"

if [[ $# -lt 2 ]]; then
    echo "No command mode specified"
    _usage 1
fi
command_mode="${2}"

if [[ ${command_mode} == "all" && ${arch} != "x86_64" ]]; then
    echo "This mode <all> needs to be run on x86_64"
    _usage 1
fi

if [[ ${command_mode} == "single" ]]; then
    work_dir=${work_dir}/${arch}
fi

setup_workdir

case "${command_name}" in
    build)
        case "${command_mode}" in
            single)
                make_common_single
                ;;
            dual)
                make_dual
                ;;
            all)
                $0 ${cmd_args} build single
                $0 ${cmd_args} purge single
                linux32 $0 ${cmd_args} build single
                linux32 $0 ${cmd_args} purge single
                $0 ${cmd_args} build dual
                $0 ${cmd_args} purge dual
                ;;
            *)
                echo "Invalid build mode '${command_mode}'"
                _usage 1
                ;;
        esac
        ;;
    purge)
        case "${command_mode}" in
            single)
                purge_single
                ;;
            dual)
                purge_dual
                ;;
            all)
                $0 ${cmd_args} purge single
                linux32 $0 ${cmd_args} purge single
                $0 ${cmd_args} purge dual
                ;;
            *)
                echo "Invalid purge mode '${command_mode}'"
                _usage 1
                ;;
        esac
        ;;
    clean)
        case "${command_mode}" in
            single)
                clean_single
                ;;
            dual)
                clean_dual
                ;;
            all)
                $0 ${cmd_args} clean single
                linux32 $0 ${cmd_args} clean single
                $0 ${cmd_args} clean dual
                ;;
            *)
                echo "Invalid clean mode '${command_mode}'"
                _usage 1
                ;;
        esac
        ;;
    *)
        echo "Invalid command name '${command_name}'"
        _usage 1
        ;;
esac
