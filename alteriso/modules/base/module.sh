#!/usr/bin/env bash
# shellcheck disable=SC2154

__alteriso_base_validate() {
    local _kernel_name
    _kernel_name=$(__alteriso_profiledef_kernelname)
    if [[ -z "$_kernel_name" || "$_kernel_name" == "null" ]]; then
        echo "[alteriso] ERROR: The base module requires a non-empty kernel_name." >&2
        exit 1
    fi
}

__alteriso_add_validator __alteriso_base_validate

__alteriso_base_setup_mkinitcpio_presets() {
    local _mkinitcpio_preset_file="$pacstrap_dir/etc/mkinitcpio.d/linux.preset.in"
    local _kernel_name
    _kernel_name=$(__alteriso_profiledef_kernelname)

    if [[ -e "${_mkinitcpio_preset_file}" ]]; then
        sed "s|%ALTERISO_KERNEL_NAME%|${_kernel_name}|g" "$_mkinitcpio_preset_file" > "$pacstrap_dir/etc/mkinitcpio.d/$_kernel_name.preset"
        rm -f "$_mkinitcpio_preset_file"
    fi
}
