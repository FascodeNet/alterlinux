#!/usr/bin/env bash
script_path=`dirname $0`
cd ${script_path}
rm -f menuconfig-script/kernel_choice_i686
rm -f menuconfig-script/kernel_choice_x86_64
for list in ${script_path}/system/kernel-* ; do
    arch="${list#${script_path}/system/kernel-}"
    for kernel in $(grep -h -v ^'#' ${list} | awk '{print $1}'); do
        echo "config KERNEL_N_A_M_E_${kernel}" >> "menuconfig-script/kernel_choice_${arch}"
        echo -e "\tbool ${kernel}" >> "menuconfig-script/kernel_choice_${arch}"
    done
done