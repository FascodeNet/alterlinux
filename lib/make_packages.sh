#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2034

make_packages_common_args(){
    local _common_arg=("-a" "${arch}" "-c" "$channel_dir" "-k" "${kernel}" "-l" "${locale_name}" "${modules[@]}" "--line")
    [[ "${boot_splash}"              = true ]] && _common_arg+=("-b")
    [[ "${debug}"                    = true ]] && _common_arg+=("-d")
    [[ "${memtest86}"                = true ]] && _common_arg+=("-m")
    [[ "${nocolor}"                  = true ]] && _common_arg+=("--nocolor")
    (( "${#additional_exclude_pkg[@]}" >= 1 )) && _common_arg+=("-e" "${additional_exclude_pkg[*]}")
    _common_arg+=("${modules[@]}")

    printf "%s\n" "${_common_arg[@]}"

    return 0
}


make_packages(){
    local _args=() _pkgs=()
    readarray -t _args < <(make_packages_common_args)
    readarray -t _pkgs < <("$script_path/tools/pkglist.sh" "${_args[@]}")
    printf "%s\n" "${_pkgs[@]}" > "$work_dir/profile/packages.${arch}"
}
