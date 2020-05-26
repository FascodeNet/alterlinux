#!/usr/bin/env bash
script_path=`dirname $0`
build_arch=$(uname -m)
cd ${script_path}
rm -f menuconfig-script/kernel_choice
kernel_list=($(cat ${script_path}/system/kernel_list-${build_arch} | grep -h -v ^'#'))
for kernel_name in ${kernel_list[@]}
do
    echo "config KERNEL_N_A_M_E_${kernel_name}" >> menuconfig-script/kernel_choice
    echo -e "\tbool ${kernel_name}" >> menuconfig-script/kernel_choice
done