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

# Base installation (root-image)
make_basefs() {
    mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" init
    mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" -p "memtest86+ mkinitcpio-nfs-utils nbd curl" install
}

# Additional packages (root-image)
make_packages() {
    mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" -p "$(grep -v ^# ${script_path}/packages.${arch})" install
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
        cp /usr/lib/initcpio/archiso_pxe_nbd ${work_dir}/root-image/usr/lib/initcpio
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
        mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" \
            -r 'mkinitcpio -c /etc/mkinitcpio-archiso.conf -k /boot/vmlinuz-linux -g /boot/archiso.img' \
            run
        mv ${_src}/boot/archiso.img ${_dst_boot}/${arch}/archiso.img
        mv ${_src}/boot/vmlinuz-linux ${_dst_boot}/${arch}/vmlinuz
        cp ${_src}/boot/memtest86+/memtest.bin ${_dst_boot}/memtest
        cp ${_src}/usr/share/licenses/common/GPL2/license.txt ${_dst_boot}/memtest.COPYING
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Prepare EFI "El Torito" boot image (using Linux >= 3.3 EFI boot stub)
make_boot_efi() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        if [[ ${arch} == "x86_64" ]]; then
            mkdir -p ${work_dir}/iso/EFI/archiso
            dd of=${work_dir}/iso/EFI/archiso/efiboot.img bs=1 seek=20M count=0
            mkfs.vfat ${work_dir}/iso/EFI/archiso/efiboot.img

            mkdir -p ${work_dir}/efiboot
            mount ${work_dir}/iso/EFI/archiso/efiboot.img ${work_dir}/efiboot

            mkdir -p ${work_dir}/efiboot/EFI/archiso
            cp ${work_dir}/iso/${install_dir}/boot/x86_64/vmlinuz ${work_dir}/efiboot/EFI/archiso/vmlinuz.efi
            cp ${work_dir}/iso/${install_dir}/boot/x86_64/archiso.img ${work_dir}/efiboot/EFI/archiso/archiso.img

            # There are plans to support command line options via a config file (not yet in linux-3.3)
            #cp ${work_dir}/iso/${install_dir}/boot/x86_64/vmlinuz ${work_dir}/efiboot/EFI/boot/bootx64.efi
            #cp ${work_dir}/iso/${install_dir}/boot/x86_64/archiso.img ${work_dir}/efiboot/EFI/boot/linux.img
            #echo "archisolabel=${iso_label} initrd=\EFI\boot\linux.img" | iconv -f ascii -t ucs2 > ${work_dir}/iso/EFI/boot/linux.conf

            # For now, provide an EFI-shell until 'linux.conf' hits mainline.
            mkdir -p ${work_dir}/efiboot/EFI/boot
            # EFI Shell 2.0 for UEFI 2.3+ ( http://sourceforge.net/apps/mediawiki/tianocore/index.php?title=UEFI_Shell )
            #wget -O ${work_dir}/efiboot/EFI/boot/bootx64.efi https://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2/ShellBinPkg/UefiShell/X64/Shell.efi
            # EFI Shell 1.0 for non UEFI 2.3+ ( http://sourceforge.net/apps/mediawiki/tianocore/index.php?title=Efi-shell )
            wget -O ${work_dir}/efiboot/EFI/boot/bootx64.efi https://edk2.svn.sourceforge.net/svnroot/edk2/trunk/edk2/EdkShellBinPkg/FullShell/X64/Shell_Full.efi

            # Add an EFI shell script for automatic boot if ESC-key is not pressed within 5 seconds timeout.
            sed "s|%ARCHISO_LABEL%|${iso_label}|g;
                 s|%INSTALL_DIR%|${install_dir}|g" ${script_path}/efiboot/EFI/boot/startup.nsh > ${work_dir}/efiboot/EFI/boot/startup.nsh

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
        wget -O - http://pciids.sourceforge.net/v2.2/pci.ids | gzip -9 > ${_dst_syslinux}/hdt/pciids.gz
        cat ${work_dir}/root-image/lib/modules/*-ARCH/modules.alias | gzip -9 > ${_dst_syslinux}/hdt/modalias.gz
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
        chmod 750 ${work_dir}/root-image/etc/sudoers.d
        chmod 440 ${work_dir}/root-image/etc/sudoers.d/g_wheel
        mkdir -p ${work_dir}/root-image/etc/pacman.d
        wget -O ${work_dir}/root-image/etc/pacman.d/mirrorlist http://www.archlinux.org/mirrorlist/all/
        sed -i "s/#Server/Server/g" ${work_dir}/root-image/etc/pacman.d/mirrorlist
        sed -i 's/#\(en_US\.UTF-8\)/\1/' ${work_dir}/root-image/etc/locale.gen
        mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" \
            -r 'locale-gen' \
            run
        mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" \
            -r 'useradd -m -p "" -g users -G "audio,disk,optical,wheel" arch' \
            run
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Split out /lib/modules from root-image (makes more "dual-iso" friendly)
make_lib_modules() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        mv ${work_dir}/root-image/lib/modules ${work_dir}/lib-modules
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

# Make [core] repository, keep "any" pkgs in a separate fs (makes more "dual-iso" friendly)
make_core_repo() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        local _url _urls _pkg_name _cached_pkg _dst _pkgs
        mkdir -p ${work_dir}/repo-core-any
        mkdir -p ${work_dir}/repo-core-${arch}
        mkdir -p ${work_dir}/pacman.db/var/lib/pacman
        pacman -Sy -r ${work_dir}/pacman.db
        _pkgs=$(comm -2 -3 <(pacman -Sql -r ${work_dir}/pacman.db core | sort | sed 's@^@core/@') \
                           <(grep -v ^# ${script_path}/core.exclude.${arch} | sort | sed 's@^@core/@'))
        _urls=$(pacman -Sddp -r ${work_dir}/pacman.db ${_pkgs})
        pacman -Swdd -r ${work_dir}/pacman.db --noprogressbar --noconfirm ${_pkgs}
        for _url in ${_urls}; do
            _pkg_name=${_url##*/}
            _cached_pkg=/var/cache/pacman/pkg/${_pkg_name}
            _dst=${work_dir}/repo-core-${arch}/${_pkg_name}
            cp ${_cached_pkg} ${_dst}
            repo-add -q ${work_dir}/repo-core-${arch}/core.db.tar.gz ${_dst}
            if [[ ${_pkg_name} == *any.pkg.tar* ]]; then
                mv ${_dst} ${work_dir}/repo-core-any/${_pkg_name}
                ln -sf ../any/${_pkg_name} ${_dst}
            fi
        done
        mkdir -p ${work_dir}/iso/${install_dir}
        pacman -Sp -r ${work_dir}/pacman.db --print-format "%r/%n-%v" ${_pkgs} | sort > ${work_dir}/iso/${install_dir}/pkglist.repo-core.${arch}.txt
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Process aitab
# args: $1 (core | netinstall)
make_aitab() {
    local _iso_type=${1}
    if [[ ! -e ${work_dir}/build.${FUNCNAME}_${_iso_type} ]]; then
        sed "s|%ARCH%|${arch}|g" ${script_path}/aitab.${_iso_type} > ${work_dir}/iso/${install_dir}/aitab
        : > ${work_dir}/build.${FUNCNAME}_${_iso_type}
    fi
}

# Build all filesystem images specified in aitab (.fs .fs.sfs .sfs)
make_prepare() {
    mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" pkglist
    mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" prepare
}

# Build ISO
# args: $1 (core | netinstall)
make_iso() {
    local _iso_type=${1}
    mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" checksum
    mkarchiso ${verbose} -w "${work_dir}" -D "${install_dir}" -L "${iso_label}" -o "${out_dir}" iso "${iso_name}-${iso_version}-${_iso_type}-${arch}.iso"
}

# Build dual-iso images from ${work_dir}/i686/iso and ${work_dir}/x86_64/iso
# args: $1 (core | netinstall)
make_dual() {
    local _iso_type=${1}
    if [[ ! -e ${work_dir}/dual/build.${FUNCNAME}_${_iso_type} ]]; then
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
        if [[ ${_iso_type} == "core" ]]; then
            if [[ ! -e ${work_dir}/dual/iso/${install_dir}/any/repo-core-any.sfs ||
                  ! -e ${work_dir}/dual/iso/${install_dir}/i686/repo-core-i686.sfs ||
                  ! -e ${work_dir}/dual/iso/${install_dir}/x86_64/repo-core-x86_64.sfs ]]; then
                    echo "ERROR: core_iso_single build is not found."
                    _usage 1
            fi
        else
            rm -f ${work_dir}/dual/iso/${install_dir}/any/repo-core-any.sfs
            rm -f ${work_dir}/dual/iso/${install_dir}/i686/repo-core-i686.sfs
            rm -f ${work_dir}/dual/iso/${install_dir}/x86_64/repo-core-x86_64.sfs
            rm -f ${work_dir}/dual/iso/${install_dir}/pkglist.repo-core.i686.txt
            rm -f ${work_dir}/dual/iso/${install_dir}/pkglist.repo-core.x86_64.txt
        fi
        paste -d"\n" <(sed "s|%ARCH%|i686|g" ${script_path}/aitab.${_iso_type}) \
                     <(sed "s|%ARCH%|x86_64|g" ${script_path}/aitab.${_iso_type}) | uniq > ${work_dir}/dual/iso/${install_dir}/aitab
        for _cfg in ${script_path}/syslinux.dual/*.cfg; do
            sed "s|%ARCHISO_LABEL%|${iso_label}|g;
                 s|%INSTALL_DIR%|${install_dir}|g" ${_cfg} > ${work_dir}/dual/iso/${install_dir}/boot/syslinux/${_cfg##*/}
        done
        mkarchiso ${verbose} -w "${work_dir}/dual" -D "${install_dir}" checksum
        mkarchiso ${verbose} -w "${work_dir}/dual" -D "${install_dir}" -L "${iso_label}" -o "${out_dir}" iso "${iso_name}-${iso_version}-${_iso_type}-dual.iso"
        : > ${work_dir}/dual/build.${FUNCNAME}_${_iso_type}
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
    make_boot_efi
    make_syslinux
    make_isolinux
    make_customize_root_image
    make_lib_modules
    make_usr_share
    make_aitab $1
    make_prepare $1
    make_iso $1
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
    echo "   build <mode> <type>"
    echo "      Build selected .iso by <mode> and <type>"
    echo "   purge <mode>"
    echo "      Clean working directory except iso/ directory of build <mode>"
    echo "   clean <mode>"
    echo "      Clean working directory and .iso file in output directory of build <mode>"
    echo
    echo " Command options:"
    echo "         <mode> Valid values 'single', 'dual' or 'all'"
    echo "         <type> Valid values 'netinstall', 'core' or 'all'"
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

if [[ ${command_name} == "build" ]]; then
    if [[ $# -lt 3 ]]; then
        echo "No build type specified"
        _usage 1
    fi
command_type="${3}"
fi

if [[ ${command_mode} == "all" && ${arch} != "x86_64" ]]; then
    echo "This mode <all> needs to be run on x86_64"
    _usage 1
fi

if [[ ${command_mode} == "single" ]]; then
    work_dir=${work_dir}/${arch}
fi

case "${command_name}" in
    build)
        case "${command_mode}" in
            single)
                case "${command_type}" in
                    netinstall)
                        make_common_single netinstall
                        ;;
                    core)
                        make_core_repo
                        make_common_single core
                        ;;
                    all)
                        make_common_single netinstall
                        make_core_repo
                        make_common_single core
                        ;;
                    *)
                        echo "Invalid build type '${command_type}'"
                        _usage 1
                        ;;
                esac
                ;;
            dual)
                case "${command_type}" in
                    netinstall)
                        make_dual netinstall
                        ;;
                    core)
                        make_dual core
                        ;;
                    all)
                        make_dual netinstall
                        make_dual core
                        ;;
                    *)
                        echo "Invalid build type '${command_type}'"
                        _usage 1
                        ;;
                esac
                ;;
            all)
                case "${command_type}" in
                    netinstall|core|all)
                        $0 ${cmd_args} build single ${command_type}
                        $0 ${cmd_args} purge single
                        linux32 $0 ${cmd_args} build single ${command_type}
                        linux32 $0 ${cmd_args} purge single
                        $0 ${cmd_args} build dual ${command_type}
                        $0 ${cmd_args} purge dual
                        ;;
                    *)
                        echo "Invalid build type '${command_type}'"
                        _usage 1
                        ;;
                esac
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
