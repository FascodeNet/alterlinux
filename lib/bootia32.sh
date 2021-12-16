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
    #if [[ " ${bootmodes[*]} " =~ ' uefi-x64.systemd-boot.esp ' ]]; then
    #    (( validation_error=validation_error+1 ))
    #    _msg_error "Using 'uefi-ia32.grub.esp' boot mode with 'uefi-x64.systemd-boot.esp' is not supported." 0
    #fi

    # Check if grub-mkstandalone is available
    if ! command -v grub-mkstandalone &> /dev/null; then
        (( validation_error=validation_error+1 ))
        _msg_error "Validating '${bootmode}': grub-mkstandalone is not available on this host. Install 'grub'!" 0
    fi

    # Check if fatresize is available
    if ! command -v fatresize &> /dev/null; then
        (( validation_error=validation_error+1 ))
        _msg_error "Validating '${bootmode}': grub-mkstandalone is not available on this host. Install 'fatresize'!" 0
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

    ## uefi-ia32.grub.eltorito conflicts with uefi-x64.systemd-boot.eltorito
    ## shellcheck disable=SC2076
    #if [[ " ${bootmodes[*]} " =~ ' uefi-x64.systemd-boot.eltorito ' ]]; then
    #    (( validation_error=validation_error+1 ))
    #    _msg_error "Using 'uefi-ia32.grub.eltorito' boot mode with 'uefi-x64.systemd-boot.eltorito' is not supported." 0
    #fi
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
    

    # Remove old BOOTia32.efi
    #remove "${isofs_dir}/EFI/BOOT/BOOT"*

    # Remove files for systemd-boot
    #remove "${isofs_dir}/loader/entries"
    
    # Create BOOTia32.efi
    grub-mkstandalone \
        -d "/usr/lib/grub/i386-efi/" \
        -O i386-efi \
        --modules="part_gpt part_msdos" \
        --fonts="unicode" \
        --locales="en@cyrillic" \
        --themes="" \
        -o "${isofs_dir}/EFI/BOOT/BOOTia32.efi" "boot/grub/grub.cfg=${_grubcfg}" -v

    # Copy grub.cfg to iso image
    install -m 0644 -- "${_grubcfg}" "${isofs_dir}/EFI/BOOT/"

}

_make_bootmode_uefi-ia32.grub.esp(){
    _run_once _make_bootmode_uefi-ia32.grub.eltorito

    #-- Increase efiboot.img size--#
    local _increase_size _loop_device
    _increase_size="$(du -bc \
        "${isofs_dir}/EFI/BOOT/BOOTia32.efi" \
        "${isofs_dir}/EFI/BOOT/grub.cfg" \
    2>/dev/null | awk 'END { print $1 }')"

    dd if=/dev/zero bs=1 count="${_increase_size}" >> "${work_dir}/efiboot.img"
    _loop_device="$(losetup -f -P --show "${work_dir}/efiboot.img")"
    fatresize -s max "${work_dir}/efiboot.img" 2> /dev/null || true

    #-- Put EFI Shell --#
    # shellx64.efi is picked up automatically when on /
    local _shell
    if [[ -e "${pacstrap_dir}/usr/share/edk2-shell/" ]]; then
        #install -m 0644 -- "${pacstrap_dir}/usr/share/edk2-shell/x64/Shell_Full.efi" "${isofs_dir}/shellx64.efi"
        for _shell in "${pacstrap_dir}/usr/share/edk2-shell/"*; do
            [[ -e "${_shell}/Shell_Full.efi" ]] && mcopy -i "${work_dir}/efiboot.img" "${_shell}/Shell_Full.efi" "::/shell$(basename "${_shell}").efi" && continue
            [[ -e "${_shell}/Shell.efi" ]] && mcopy -i "${work_dir}/efiboot.img" "${_shell}/Shell.efi" "::/shell$(basename "${_shell}").efi"
        done
    fi

    #-- Put kernel and initrd --#
    # Copy kernel and initramfs to FAT image.
    # grub can only access files from the EFI system partition it was launched from.
    _make_boot_on_fat

    #-- Copy grub --#
    #mdeltree -i "${work_dir}/efiboot.img" ::/loader/ ::/EFI/ 2> /dev/null || true
    #mmd -i "${work_dir}/efiboot.img" "::/EFI" "::/EFI/BOOT"
    mcopy -i "${work_dir}/efiboot.img" "${isofs_dir}/EFI/BOOT/BOOTia32.efi" ::/EFI/BOOT/
    mcopy -i "${work_dir}/efiboot.img" "${isofs_dir}/EFI/BOOT/grub.cfg" ::/EFI/BOOT/

    _msg_info "Done! grub set up for UEFI booting successfully."
}

# systemd-boot in an attached EFI system partition
_add_xorrisofs_options_uefi-ia32.grub.esp() {
    _add_xorrisofs_options_uefi-x64.systemd-boot.esp
}

# systemd-boot via El Torito
_add_xorrisofs_options_uefi-ia32.grub.eltorito() {
    _add_xorrisofs_options_uefi-x64.systemd-boot.eltorito
}
