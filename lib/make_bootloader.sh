#!/usr/bin/env bash
# shellcheck disable=SC2154

make_bootloader(){
    cp -r "${script_path}/profile_template/efiboot" "$work_dir/profile"
    cp -r "${script_path}/profile_template/syslinux" "$work_dir/profile"
    cp -r "${script_path}/archiso/configs/releng/grub" "$work_dir/profile"
}
