#!/usr/bin/env bash
# shellcheck disable=SC2154


build_template_parser(){
    (
        cd "${script_path}/lib/template_parser" || exit 1
        go build -o "$template_parser" .
    )
}

parse_template(){
    local _file="$1"
    shift 1 || return 1
    "$template_parser" "$_file" "$(make_parser_args "$@")"
}

_array_to_json(){
    local _json
    _json="$(eval "printf \"\\\"%s\\\",\" \"\${${1}[@]}\"")"
    echo "\"${1}\": [${_json%,}]"
}

_dic_to_json(){
    local _array="" _i="" _dic="$1"
    while read -r _i; do
        _array="${_array}\"${_i}\": \"$(eval "echo \"\${${_dic}[${_i}]}\"")\","
    done < <(eval "printf \"%s\n\" \"\${!${_dic}[@]}\" ")
    echo "\"${_dic}\": {${_array%,}}"
}

_var_to_json(){
    local _json _var="$1"
    echo "\"${_var}\": \"$(eval "echo \"\${${_var}}\"")\""
}

make_parser_args(){
    local _v _j
    local _json_var="" _json_arr="" _json_dic=""
    for _v in "$@"; do
        [[ -n "${_v}"  ]] || continue
        if declare -p "$_v" 2> /dev/null | grep -- "declare -a" 2> /dev/null 1>&2; then
            _json_arr="${_json_arr}$(_array_to_json "$_v"),"
        elif declare -p "$_v" 2> /dev/null | grep -- "declare -A" 2> /dev/null  1>&2; then
            _json_dic="${_json_dic}$(_dic_to_json "${_v}"),"
        else
            _json_var="${_json_var}$(_var_to_json "${_v}"),"
        fi
    done

    _json_arr="${_json_arr%,}"
    _json_dic="${_json_dic%,}"
    _json_var="${_json_var%,}"

    local _json=""
    for _j in "$_json_arr" "$_json_dic" "$_json_var"; do
        [[ -n "${_j}" ]] || continue
        _json="${_json}${_j},"
    done
    
    echo "{${_json%,}}"
}
