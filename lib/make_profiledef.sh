#!/usr/bin/env bash
# shellcheck disable=SC2154

make_profiledef(){
    local _base="${template_dir}/profiledef.sh" _args=()
    

    parse_template "$_base" iso_name
}


