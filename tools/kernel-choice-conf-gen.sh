#!/usr/bin/env bash

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
arch_list=(
    "x86_64"
    "i686"
)

# rm helper
# Delete the file if it exists.
# For directories, rm -rf is used.
# If the file does not exist, skip it.
# remove <file> <file> ...
remove() {
    local _list=($(echo "$@")) _file
    for _file in "${_list[@]}"; do
        if [[ -f "${_file}" ]]; then    
            rm -f "${_file}"
        elif [[ -d "${_file}" ]]; then
            rm -rf "${_file}"
        fi
    done
}

#cd "${script_path}"
for arch in ${arch_list[@]}; do
    remove "${script_path}/menuconfig-script/kernel_choice_${arch}"
    for kernel in $(bash "${script_path}/tools/kernel.sh" -a "${arch}" show ); do
        echo "config KERNEL_N_A_M_E_${kernel}" >> "${script_path}/menuconfig-script/kernel_choice_${arch}"
        echo -e "\tbool ${kernel}" >> "${script_path}/menuconfig-script/kernel_choice_${arch}"
    done
done
