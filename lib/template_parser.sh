#!/usr/bin/env bash
# shellcheck disable=SC2154


build_template_parser(){
    {
        cd "${script_path}/lib/template_parser" || exit 1
        go build -o "$template_parser" .
    }
}

parse_template(){
    "$template_parser" "$@"
}

make_parser_args(){
    local _v _args=()
    for _v in "$@"; do
        _args+=("${_v}=$(eval "echo \"\${$_v}\"")")
    done
    printf "%s\n" "${_args[@]}"
}
