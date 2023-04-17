#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2034

make_prepare(){
    # set args
    work_dir="$(realpath "$work_dir")"

    # build tool
    template_parser="${work_dir}/template_parser"
    build_template_parser
}
