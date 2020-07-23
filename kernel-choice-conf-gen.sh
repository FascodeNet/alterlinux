#!/usr/bin/env bash
script_path=`dirname $0`
cd ${script_path}
rm -f menuconfig-script/kernel_choice_i686
rm -f menuconfig-script/kernel_choice_x86_64
kernel_list=($(cat ${script_path}/system/kernel_list-i686 | grep -h -v ^'#'))
for kernel_name in ${kernel_list[@]}
do
    echo "config KERNEL_N_A_M_E_${kernel_name}" >> menuconfig-script/kernel_choice_i686
    echo -e "\tbool ${kernel_name}" >> menuconfig-script/kernel_choice_i686
done
kernel_list=($(cat ${script_path}/system/kernel_list-x86_64 | grep -h -v ^'#'))
for kernel_name in ${kernel_list[@]}
do
    echo "config KERNEL_N_A_M_E_${kernel_name}" >> menuconfig-script/kernel_choice_x86_64
    echo -e "\tbool ${kernel_name}" >> menuconfig-script/kernel_choice_x86_64
done