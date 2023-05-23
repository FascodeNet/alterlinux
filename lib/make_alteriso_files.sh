#!/usr/bin/env bash
# shellcheck disable=SC2154

make_alteriso_files(){
    mkdir -p "$work_dir/profile/alteriso"
    cp "$script_path/system/scripts/"* "$work_dir/profile/alteriso"
}
