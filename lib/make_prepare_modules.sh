#!/usr/bin/env bash

make_prepare_modules(){
    # Add additional modules
    modules+=("${additional_modules[@]}")

    readarray -t modules < <(parser_preset "${modules[@]}")
    msg_debug "Loaded modules: ${modules[*]}"
}

# Execute command for each module. It will be executed with {} replaced with the module name.
# for_module <command>
for_module(){ 
    local module
    for module in "${modules[@]}"; do 
        eval "${@//"{}"/${module}}"
    done
}


#parse_preset(){
#    # Load presets
#    local _modules=() module_check
#    for_module '[[ -f "${preset_dir}/{}" ]] && readarray -t -O "${#_modules[@]}" _modules < <(grep -h -v ^'#' "${preset_dir}/{}") || _modules+=("{}")'
#    modules=("${_modules[@]}")
#    unset _modules
#}

# parse_preset <modules>
# 引数にモジュールとプリセットがごっちゃになってる配列を展開して渡すと、モジュールだけを返してくれます
parser_preset(){
    local _p _modules=()
    for _p in "$@"; do
        if [[ -f "${modules_dir}/$_p" ]]; then
            msg_debug "Found $_p as preset"
            readarray -t -O "${#_modules[@]}" _modules < <(grep -h -v ^'#' "${modules_dir}/${_p}")
        else
            _modules+=("$_p")
        fi
    done
    printf "%s\n" "${_modules[@]}"
    return 0
}
