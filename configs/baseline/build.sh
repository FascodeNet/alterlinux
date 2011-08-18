#!/bin/bash

set -e -u

name=archlinux
iso_label="ARCH_$(date +%Y%m)"
version=$(date +%Y.%m.%d)
install_dir=arch
arch=$(uname -m)
work_dir=work
verbose="n"

script_path=$(readlink -f ${0%/*})

# Base installation (root-image)
make_basefs() {
    mkarchiso ${verbose} -D "${install_dir}" -p "base" create "${work_dir}"
    mkarchiso ${verbose} -D "${install_dir}" -p "syslinux" create "${work_dir}"
}

# Copy mkinitcpio archiso hooks (root-image)
make_setup_mkinitcpio() {
   if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        cp /lib/initcpio/hooks/archiso ${work_dir}/root-image/lib/initcpio/hooks
        cp /lib/initcpio/install/archiso ${work_dir}/root-image/lib/initcpio/install
        : > ${work_dir}/build.${FUNCNAME}
   fi
}

# Prepare ${install_dir}/boot/
make_boot() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        mkdir -p ${work_dir}/iso/${install_dir}/boot/${arch}
        mkinitcpio \
            -c ${script_path}/mkinitcpio.conf \
            -b ${work_dir}/root-image \
            -k /boot/vmlinuz-linux \
            -g ${work_dir}/iso/${install_dir}/boot/${arch}/archiso.img
        cp ${work_dir}/root-image/boot/vmlinuz-linux ${work_dir}/iso/${install_dir}/boot/${arch}/vmlinuz
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Prepare /${install_dir}/boot/syslinux
make_syslinux() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        mkdir -p ${work_dir}/iso/${install_dir}/boot/syslinux
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
            s|%INSTALL_DIR%|${install_dir}|g;
            s|%ARCH%|${arch}|g" ${script_path}/syslinux/syslinux.cfg > ${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg
        cp ${work_dir}/root-image/usr/lib/syslinux/menu.c32 ${work_dir}/iso/${install_dir}/boot/syslinux/
        : > ${work_dir}/build.${FUNCNAME}
    fi
}

# Prepare /isolinux
make_isolinux() {
    if [[ ! -e ${work_dir}/build.${FUNCNAME} ]]; then
        mkdir -p ${work_dir}/iso/isolinux
        sed "s|%INSTALL_DIR%|${install_dir}|g" ${script_path}/isolinux/isolinux.cfg > ${work_dir}/iso/isolinux/isolinux.cfg
        cp ${work_dir}/root-image/usr/lib/syslinux/isolinux.bin ${work_dir}/iso/isolinux/
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
    mkarchiso ${verbose} -D "${install_dir}" prepare "${work_dir}"
}

# Build ISO
make_iso() {
    mkarchiso ${verbose} -D "${install_dir}" checksum "${work_dir}"
    mkarchiso ${verbose} -D "${install_dir}" -L "${iso_label}" iso "${work_dir}" "${name}-${version}-${arch}.iso"
}

if [[ $verbose == "y" ]]; then
    verbose="-v"
else
    verbose=""
fi

make_basefs
make_setup_mkinitcpio
make_boot
make_syslinux
make_isolinux
make_aitab
make_prepare
make_iso
