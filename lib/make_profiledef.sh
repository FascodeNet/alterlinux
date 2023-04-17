#!/usr/bin/env bash
# shellcheck disable=SC2154

make_profiledef(){
    local _base="${template_dir}/profiledef.sh" _args=()
    
    readarray -t _args < <(
        make_parser_args \
            iso_name

    )

    parse_template "$_base" "${_args[@]}"
}


