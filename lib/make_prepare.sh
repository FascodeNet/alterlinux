#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2034

make_prepare(){
    # set up dir
    work_dir="$(realpath "$work_dir")"
    mkdir -p "$work_dir/profile"

    # build tool
    template_parser="${work_dir}/template_parser"
    build_template_parser

    list_parser="${work_dir}/list_parser"
    build_list_parser
}

make_default(){
    if [[ -z "$kernel" ]]; then
        kernel="$defaultkernel"
    fi
    
}

make_parsed_vars(){
    # kernel
    local kernel_listfile="${script_path}/system/kernel-list/kernel-$arch"
    if [[ ! -f "$kernel_listfile" ]]; then
        msg_err "Kernel list file not found: $kernel_listfile"
        exit 1
    fi
    eval "$(parse_list kernel "$kernel_listfile" "$kernel")"
}
