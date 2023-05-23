#!/usr/bin/env bash
# shellcheck disable=SC2154

exec_archiso(){
    bash "${script_path}/archiso/archiso/mkarchiso" -v -w "$work_dir/build" -o "$out_dir" "$@" "$work_dir/profile"
}
