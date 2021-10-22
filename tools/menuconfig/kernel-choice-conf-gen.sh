#!/usr/bin/env bash

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
arch_list=(
    "x86_64"
    "i686"
)

#cd "${script_path}"
for arch in "${arch_list[@]}"; do
    rm -rf "${script_path}/menuconfig-script/kernel_choice_${arch}"
    for kernel in $(bash "${script_path}/tools/kernel.sh" -a "${arch}" show ); do
        echo "config KERNEL_N_A_M_E_${kernel}" >> "${script_path}/menuconfig-script/kernel_choice_${arch}"
        echo -e "\tbool ${kernel}" >> "${script_path}/menuconfig-script/kernel_choice_${arch}"
    done
done
