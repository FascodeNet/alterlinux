#!/usr/bin/env bash
# shellcheck disable=SC2154

build_list_parser(){
    {
        cd "${script_path}/lib/list_parser" || exit 1
        go build -o "$list_parser" .
    }
}

parse_list(){
    "$list_parser" "${@}" 
}
