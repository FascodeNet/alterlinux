#!/usr/bin/env bash
#
# Yamada Hayao
# Twitter: @Hayao0819
# Email  : hayao@fascode.net
#
# (c) 2019-2021 Fascode Network.
#
# bootia32.sh
#
# Add support for IA32 UEFI with Grub
# This script provides uefi-ia32.grub.esp and uefi-ia32.grub.eltorito bootmode
#
# Special Thanks: https://github.com/ElXreno/archlinux-bootia32
#


_validate_requirements_bootmode_uefi-ia32.grub.esp(){
    _validate_requirements_bootmode_bios.syslinux.mbr
    _validate_requirements_bootmode_uefi-x64.systemd-boot.esp

    # uefi-ia32.grub.esp conflicts with uefi-x64.systemd-boot.esp
    # shellcheck disable=SC2076
    if [[ " ${bootmodes[*]} " =~ ' uefi-x64.systemd-boot.esp ' ]]; then
        (( validation_error=validation_error+1 ))
        _msg_error "Using 'uefi-ia32.grub.esp' boot mode with 'uefi-x64.systemd-boot.esp' is not supported." 0
    fi

    # Check if grub-mkstandalone is available
    if ! command -v grub-mkstandalone &> /dev/null; then
        (( validation_error=validation_error+1 ))
        _msg_error "Validating '${bootmode}': grub-mkstandalone is not available on this host. Install 'grub'!" 0
    fi
}

_validate_requirements_bootmode_uefi-ia32.grub.eltorito(){
    _validate_requirements_bootmode_uefi-ia32.grub.esp

    # uefi-ia32.grub.eltorito requires uefi-ia32.grub.esp
    # shellcheck disable=SC2076
    if [[ ! " ${bootmodes[*]} " =~ ' uefi-ia32.grub.esp ' ]]; then
        (( validation_error=validation_error+1 ))
        _msg_error "Using 'uefi-ia32.grub.eltorito' boot mode without 'uefi-ia32.grub.esp' is not supported." 0
    fi

    # uefi-ia32.grub.eltorito conflicts with uefi-x64.systemd-boot.eltorito
    # shellcheck disable=SC2076
    if [[ " ${bootmodes[*]} " =~ ' uefi-x64.systemd-boot.eltorito ' ]]; then
        (( validation_error=validation_error+1 ))
        _msg_error "Using 'uefi-ia32.grub.eltorito' boot mode with 'uefi-x64.systemd-boot.eltorito' is not supported." 0
    fi
}

_make_bootmode_uefi-ia32.grub.eltorito(){
    local _grubcfg="${build_dir}/grub.cfg"

    # UEFI ia32 requires EFI config files for systemd-boot
    _run_once _make_bootmode_uefi-x64.systemd-boot.eltorito

    # _get_efiboot_entry <path> <key>
    _get_efiboot_entry(){
        awk "{
            if (\$1 == \"${2}\"){
                print \$0
            }
        }" "${1}" | cut -d " " -f 2-
    }

    # Setup grub.cfg
    cat "${script_path}/system/grub/grub-head.cfg" > "${_grubcfg}"

    local _cfg
    for _cfg in "${isofs_dir}/loader/entries/"*".conf"; do
        sed -e "
            s|%EFI_TITLE%|$(_get_efiboot_entry "${_cfg}" "title" | sed -e "s|^ *||g")|g;
            s|%EFI_LINUX%|$(_get_efiboot_entry "${_cfg}" "linux")|g;
            s|%EFI_OPTIONS%|$(_get_efiboot_entry "${_cfg}" "options")|g;
            s|%ARCHISO_LABEL%|${iso_label}|g;

            $(
                while read -r _initrd; do
                    echo "/initrd %EFI_INITRD%/a\    initrd ${_initrd};"
                done < <(_get_efiboot_entry "${_cfg}" initrd)
            )
        " "${script_path}/system/grub/grub-entry.cfg" | grep -Exv " +initrd %EFI_INITRD%">> "${_grubcfg}"
    done
    

    # Remove old bootia32.efi
    remove "${isofs_dir}/EFI/BOOT/BOOT"*

    # Remove files for systemd-boot
    remove "${isofs_dir}/loader/entries"
    
    # Create bootia32.efi
    grub-mkstandalone \
        -d /usr/lib/grub/i386-efi/ \
        -O i386-efi \
        --modules="part_gpt part_msdos" \
        --fonts="unicode" \
        --locales="en@cyrillic" \
        --themes="" \
        -o "${isofs_dir}/EFI/BOOT/bootia32.efi" "boot/grub/grub.cfg=${_grubcfg}" -v

}

_make_bootmode_uefi-ia32.grub.esp(){
    mdeltree -i "${work_dir}/efiboot.img" ::/loader/ ::/EFI/
    mmd -i "${work_dir}/efiboot.img" ::/EFI/BOOT/
    mcopy -i "${work_dir}/efiboot.img" "${isofs_dir}/EFI/BOOT/bootia32.efi" ::/EFI/BOOT/
}
