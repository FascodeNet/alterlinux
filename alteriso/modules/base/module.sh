#!/usr/bin/env bash
# shellcheck disable=SC2154

__alteriso_base_setup_mkinitcpio_presets() {
    local _mkinitcpio_preset_file="$pacstrap_dir/etc/mkinitcpio.d/linux.preset.in"
    local _kernel_name
    _kernel_name=$(__alteriso_profiledef_kernel_name)

    if [[ -e "${_mkinitcpio_preset_file}" ]]; then
        sed "s|%ALTERISO_KERNEL_NAME%|${_kernel_name}|g" "$_mkinitcpio_preset_file" "$pacstrap_dir/etc/mkinitcpio.d/$__alteriso_profiledef_kernelname.preset"
        rm -f "$_mkinitcpio_preset_file"
    fi
}
