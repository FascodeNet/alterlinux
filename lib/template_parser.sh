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
        if declare -p "$_v" | grep -- "declare -a" 2> /dev/null 1>&2; then
            # 配列
            _args+=("$_v=$(  array_to_csv "$_v" )")
        else
            _args+=("${_v}=$(eval "echo \"\${$_v}\"")")
        fi
    done
    printf "%s\n" "${_args[@]}"
}

array_to_csv(){
    local _csv
    _csv="$(eval "printf \"%s,\" \"\${${1}[@]}\"")"
    echo "${_csv%,}"
}
