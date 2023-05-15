#!/usr/bin/env bash
# shellcheck disable=SC2154

make_bootloader(){
    cp -r "${script_path}/efiboot" "$work_dir"
    cp -r "${script_path}/syslinux" "$work_dir"
}
