#!/usr/bin/env bash

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
arch_list=(
    "x86_64"
    "i686"
)

#cd "${script_path}"
for arch in "${arch_list[@]}"; do
    rm -rf "${script_path}/menuconfig-script/channels_menuconfig-${arch}"
    for channel in $(bash "${script_path}/tools/channel.sh" -a "${arch}" show ); do
        echo "config CHANNEL_N_A_M_E_${channel}" >> "${script_path}/menuconfig-script/channels_menuconfig-${arch}"
        echo -e "\tbool ${channel}" >> "${script_path}/menuconfig-script/channels_menuconfig-${arch}"
    done
done
