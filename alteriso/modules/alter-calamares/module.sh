#!/usr/bin/env bash
# shellcheck disable=SC2154
# LLM Generated: Created by Claude

__alteriso_calamares_replace_username() {
    local _username
    _username=$(__alteriso_profiledef_username)
    sed -i "s|%USERNAME%|${_username}|g" "$pacstrap_dir/etc/calamares/modules/removeuser.conf"
}

__alteriso_calamares_replace_kernel() {
    local _kernel
    _kernel=$(__alteriso_profiledef_kernelname)
    sed -i "s|%KERNEL_NAME%|${_kernel}|g" "$pacstrap_dir/etc/calamares/modules/initcpio.conf"
}

__alteriso_calamares_customize_airootfs() {
    __alteriso_calamares_replace_username
    __alteriso_calamares_replace_kernel
}
