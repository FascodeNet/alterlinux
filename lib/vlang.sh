_vlang_tool(){
    local _t="$1"
    shift 1 || return 0
    [[ -d "$tools_dir/vlang/$_t" ]] || {
        exit 1
    }

    [[ -e "$tools_dir/vlang/$_t/$_t" ]] || {
        exit 1
    }
    

    "$tools_dir/vlang/$_t/$_t" "$@"
}
