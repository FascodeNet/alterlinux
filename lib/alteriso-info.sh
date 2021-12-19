#!/usr/bin/env bash
_alteriso_info(){
    echo "Developer      : ${iso_publisher}"
    echo "OS Name        : ${iso_application}"
    echo "Architecture   : ${arch}"
    if [[ -d "${script_path}/.git" ]] && [[ "${gitversion}" = false ]];then 
        echo "Version        : ${iso_version}-${gitrev}"
    else
        echo "Version        : ${iso_version}"
    fi
    echo "Channel   name : ${channel_name}"
    echo "Live user name : ${username}"
    echo "Live user pass : ${password}"
    echo "Kernel    name : ${kernel}"
    echo "Kernel    path : ${kernel_filename}"
    [[ "${#modules[@]}" != 0 ]] && echo "Loaded modules : ${modules[*]}"
    if [[ "${boot_splash}" = true ]]; then
        echo "Plymouth       : Yes"
    else
        echo "Plymouth       : No"
    fi
}
