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
    local usagetext
    IFS='' read -r -d '' usagetext <<EOF || true
Usage:
    ${app_name} [options]

Options:
    -A [arch]       change architecture (defaults to the host architecture; supports: x86_64, i686, aarch64 and riscv64)
    -a              set accessibility support using brltty
    -b              set boot type to 'BIOS'
    -d              set image type to hard disk instead of optical disc
    -h              print help
    -i [image]      image to boot into
    -s              use Secure Boot (only relevant when using UEFI)
    -u              set boot type to 'UEFI' (default)
    -v              use VNC display (instead of default SDL)
    -c [image]      attach an additional optical disc image (e.g. for cloud-init)

Example:
    Run an image using UEFI:
    $ run_archiso -i archiso-2020.05.23-x86_64.iso
EOF
    printf '%s' "${usagetext}"
}

cleanup_working_dir() {
    if [[ -d "${working_dir}" ]]; then
        rm -rf -- "${working_dir}"
    fi
}

check_architecture() {
    if [[ "$boot_type" == 'bios' ]]; then
        if [[ "$arch" != @('i686'|'x86_64') ]]; then
            printf '[%s] Error: Unsupported architecture for the BIOS boot method: %s\n' "$app_name" "$arch" >&2
            printf '[%s] Error: The BIOS boot method is supported on: %s\n' "$app_name" 'x86_64 i686' >&2
            exit 1
        fi
    else
        if ! [[ -v ovmf_code["$arch"] && -v ovmf_vars["$arch"] ]]; then
            printf '[%s] Error: Unsupported architecture for the UEFI boot method: %s\n' "$app_name" "$arch" >&2
            printf '[%s] Error: The UEFI boot method is supported on: %s\n' "$app_name" "${!ovmf_code[*]}" >&2
            exit 1
        elif ! [[ -f "${ovmf_code[$arch]}" && -f "${ovmf_vars[$arch]}" ]]; then
            printf '[%s] ERROR: %s not found. Install OVMF for %s.\n' "$app_name" "${ovmf_vars[$arch]}" "$arch" >&2
            exit 1
        fi
    fi

    case "$arch" in
        i686) qemu_command='qemu-system-i386' ;;
        *) qemu_command="qemu-system-${arch}" ;;
    esac
    if ! command -v "$qemu_command" %>/dev/null; then
        printf '[%s] ERROR: %s not found. Install QEMU for %s.\n' "$app_name" "$qemu_command" "$arch" >&2
        exit 1
    fi
}

check_image() {
    if [[ -z "$image" ]]; then
        printf '[%s] ERROR: Image name can not be empty.\n' "$app_name" >&2
        exit 1
    fi
    if [[ ! -f "$image" ]]; then
        printf '[%s] ERROR: Image file (%s) does not exist.\n' "$app_name" "$image" >&2
        exit 1
    fi
}

run_image() {
    local -a qemu_options

    # Set default qemu options
    qemu_options=(
        -boot 'order=d,menu=on,reboot-timeout=5000'
        -m "size=3072,slots=0,maxmem=$((3072*1024*1024))"
        -cpu max
        -smp 4
        -k en-us
        -name 'archiso,process=archiso_0'
        -device 'virtio-scsi-pci,id=scsi0'
        -display "${display}"
        -audiodev 'pa,id=snd0'
        -device ich9-intel-hda
        -device 'hda-output,audiodev=snd0'
        -device 'virtio-net-pci,romfile=,netdev=net0'
        -netdev 'user,id=net0,hostfwd=tcp::60022-:22'
        -device qemu-xhci
        -device usb-kbd
        -device usb-mouse
        -device usb-tablet
        -device "scsi-${mediatype%rom},bus=scsi0.0,drive=${mediatype}0"
        -drive "id=${mediatype}0,if=none,format=raw,media=${mediatype/hd/disk},read-only=on,file=${image}"
        -serial stdio
        -no-reboot
    )

    # Use KVM acceleration if possible
    if [[ "$arch" == "$(uname -m)" || ( "$arch" == 'i686' && "$(uname -m)" == 'x86_64' ) ]]; then
        qemu_options+=(-enable-kvm)
    fi

    # Set architecture-specific options
    case "$arch" in
        x86_64|i686)
            qemu_options=(
                -machine "type=q35,smm=on,usb=on,pcspk-audiodev=snd0"
                -global ICH9-LPC.disable_s3=1
                -vga virtio
                "${qemu_options[@]}"
            )
            ;;
        aarch64|riscv64)
            qemu_options=(
                -machine "type=virt,usb=on,acpi=on"
                -device 'virtio-gpu-pci,id=video0'
                "${qemu_options[@]}"
            )
            ;;
    esac

    if [[ "$boot_type" == 'uefi' ]]; then
        cp -av -- "${ovmf_vars[$arch]}" "${working_dir}/"

        qemu_options+=(
            '-drive' "if=pflash,format=raw,unit=0,file=${ovmf_code[$arch]},read-only=on"
            '-drive' "if=pflash,format=raw,unit=1,file=${working_dir}/${ovmf_vars[$arch]##*/}"
        )

        if (( secure_boot )); then
            printf '[%s] Using Secure Boot\n' "$app_name"
            qemu_options+=('-global' 'driver=cfi.pflash01,property=secure,value=on')
        else
            qemu_options+=('-global' 'driver=cfi.pflash01,property=secure,value=off')
        fi
    fi

    if (( accessibility )); then
        qemu_options+=(
            '-chardev' 'braille,id=brltty'
            '-device' 'usb-braille,id=usbbrl,chardev=brltty'
        )
    fi

    if [[ -n "${oddimage}" ]]; then
        qemu_options+=(
            '-device' 'scsi-cd,bus=scsi0.0,drive=cdrom1'
            '-drive' "id=cdrom1,if=none,format=raw,media=cdrom,read-only=on,file=${oddimage}"
        )
    fi

    if (( use_vnc )); then
        qemu_options+=(-vnc 'vnc=0.0.0.0:0,vnc=[::]:0')
    fi

    "$qemu_command" "${qemu_options[@]}"
}

readonly app_name="${0##*/}"
arch="$(uname -m)"
image=''
oddimage=''
declare -i accessibility=0
boot_type='uefi'
mediatype='cdrom'
declare -i secure_boot=0
declare -i use_vnc=0
display='sdl'
qemu_command=''
working_dir="$(mktemp -dt run_archiso.XXXXXXXXXX)"
readonly -A ovmf_code=(['x86_64']='/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd'
                       ['aarch64']='/usr/share/edk2/aarch64/QEMU_CODE.fd'
                       ['riscv64']='/usr/share/edk2/riscv64/RISCV_VIRT_CODE.fd')
readonly -A ovmf_vars=(['x86_64']='/usr/share/edk2/x64/OVMF_VARS.4m.fd'
                       ['aarch64']='/usr/share/edk2/aarch64/QEMU_VARS.fd'
                       ['riscv64']='/usr/share/edk2/riscv64/RISCV_VIRT_VARS.fd')
trap cleanup_working_dir EXIT

if (( ${#@} > 0 )); then
    while getopts 'A:abc:dhi:suv' flag; do
        case "$flag" in
            A)
                arch="${OPTARG,,}"
                ;;
            a)
                accessibility=1
                ;;
            b)
                boot_type='bios'
                ;;
            c)
                oddimage="$OPTARG"
                ;;
            d)
                mediatype='hd'
                ;;
            h)
                print_help
                exit 0
                ;;
            i)
                image="$OPTARG"
                ;;
            u)
                boot_type='uefi'
                ;;
            s)
                secure_boot=1
                ;;
            v)
                display='none'
                use_vnc=1
                ;;
            *)
                printf '[%s] Error: Wrong option. Try "%s -h".\n' "$app_name" "$app_name" >&2
                exit 1
                ;;
        esac
    done
else
    print_help
    exit 1
fi

check_architecture
check_image
run_image
