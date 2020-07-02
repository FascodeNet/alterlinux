#!/usr/bin/env bash
#
# Copyright (C) 2020 David Runge <dvzrv@archlinux.org>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# A simple script to run an archiso image using qemu. The image can be booted
# using BIOS or UEFI.
#
# Requirements:
# - qemu
# - edk2-ovmf (when UEFI booting)


set -eu

print_help() {
    cat << EOF
Usage:
    run_archiso [options]

Options:
    -b              set boot type to 'bios' (default)
    -h              print help
    -i [image]      image to boot into
    -s              use secure boot (only relevant when using UEFI)
    -u              set boot type to 'uefi'

Example:
    Run an image using UEFI:
    $ run_archiso -u -i archiso-2020.05.23-x86_64.iso
EOF
}

cleanup_working_dir() {
    if [ -d "${working_dir}" ]; then
        rm -rf "${working_dir}"
    fi
}

copy_ovmf_vars() {
    if [ ! -f /usr/share/edk2-ovmf/x64/OVMF_VARS.fd ]; then
        echo "ERROR: OVMF_VARS.fd not found. Install edk2-ovmf."
        exit 1
    fi
    cp -av /usr/share/edk2-ovmf/x64/OVMF_VARS.fd "${working_dir}"
}

check_image() {
    if [ -z "$image" ]; then
        echo "ERROR: Image name can not be empty."
        exit 1
    fi
    if [ ! -f "$image" ]; then
        echo "ERROR: Image file ($image) does not exist."
        exit 1
    fi
}

run_image() {
    [ "$boot_type" == "bios" ] && run_image_using_bios
    [ "$boot_type" == "uefi" ] && run_image_using_uefi
}

run_image_using_bios() {
    qemu-system-x86_64 \
        -boot order=d,menu=on,reboot-timeout=5000 \
        -m size=3072,slots=0,maxmem=$((3072*1024*1024)) \
        -k en \
        -name archiso,process=archiso_0 \
        -drive file="${image}",media=cdrom,readonly=on,if=virtio \
        -display sdl \
        -vga virtio \
        -device virtio-net-pci,netdev=net0 -netdev user,id=net0 \
        -enable-kvm \
        -no-reboot
}

run_image_using_uefi() {
    local ovmf_code=/usr/share/edk2-ovmf/x64/OVMF_CODE.fd
    local secure_boot_state=off
    copy_ovmf_vars
    if [ "${secure_boot}" == "yes" ]; then
        echo "Using Secure Boot"
        ovmf_code=/usr/share/edk2-ovmf/x64/OVMF_CODE.secboot.fd
        secure_boot_state=on
    fi
    qemu-system-x86_64 \
        -boot order=d,menu=on,reboot-timeout=5000 \
        -m size=3072,slots=0,maxmem=$((3072*1024*1024)) \
        -k en \
        -name archiso,process=archiso_0 \
        -drive file="${image}",media=cdrom,readonly=on,if=virtio \
        -drive if=pflash,format=raw,unit=0,file="${ovmf_code}",readonly \
        -drive if=pflash,format=raw,unit=1,file="${working_dir}/OVMF_VARS.fd" \
        -machine type=q35,smm=on,accel=kvm \
        -global driver=cfi.pflash01,property=secure,value="${secure_boot_state}" \
        -global ICH9-LPC.disable_s3=1 \
        -display sdl \
        -vga virtio \
        -device virtio-net-pci,netdev=net0 -netdev user,id=net0 \
        -enable-kvm \
        -no-reboot
}

set_image() {
    if [ -z "$image" ]; then
        echo "ERROR: Image name can not be empty."
        exit 1
    fi
    if [ ! -f "$image" ]; then
        echo "ERROR: Image ($image) does not exist."
        exit 1
    fi
    image="$1"
}

image=""
boot_type="bios"
secure_boot="no"
working_dir="$(mktemp -d)"
trap cleanup_working_dir EXIT

if [ ${#@} -gt 0 ]; then
    while getopts 'bhi:su' flag; do
        case "${flag}" in
            b)
                boot_type=bios
                ;;
            h)
                print_help
                exit 0
                ;;
            i)
                image="$OPTARG"
                ;;
            u)
                boot_type=uefi
                ;;
            s)
                secure_boot=yes
                ;;
            *)
                echo "Error: Wrong option. Try 'run_archiso -h'."
                exit 1
                ;;
        esac
    done
else
    print_help
    exit 1
fi

check_image
run_image
