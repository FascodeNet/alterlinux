#!/usr/bin/env bash
script_path=`dirname $0`

build_arch=x86_64

machine_arch=$(uname -m)
cd ${script_path} 
if [ $# -ne 1 ]; then
    echo "error!" 1>&2
    echo "You must set one arg!" 1>&2
    exit 1
fi
#build.shのオプションに使う変数を設定
buf=`grep CONFIG_I686_BUILD .config`
eval "$buf"
if [[ $CONFIG_I686_BUILD = "y" ]]; then
    build_arch=i686
fi
buf=`grep CONFIG_KERNEL_N_A_M_E_ .config | sed -e 's/=y//g' | sed -e 's/CONFIG_KERNEL_N_A_M_E_/kernel=/g'`
eval "$buf"
buf=`grep CONFIG_ENABLE_PLYMOUTH .config | sed -e 's/y/true/g' | sed -e 's/CONFIG_ENABLE_PLYMOUTH/plymouth/g'`
eval "$buf"
buf=`grep CONFIG_USE_CUSTOM_LANG .config | sed -e 's/y/true/g' | sed -e 's/CONFIG_USE_CUSTOM_LANG/USE_CUSTOM_LANG/g'`
eval "$buf"
buf=`grep CONFIG_SFS_CMP_ .config | sed -e 's/=y//g' | sed -e 's/CONFIG_SFS_CMP_/comp_type=/g'`
eval "${buf,,}"
buf=`grep CONFIG_USE_SFS_OPTION .config | sed -e 's/y/true/g'`
eval "$buf"
if [[ $CONFIG_USE_SFS_OPTION ]]; then
    if [[ $comp_type = "zstd" ]]; then
        buf=`grep CONFIG_ZSTD_COMP_LVL .config`
        eval "$buf"
        comp_option="-Xcompression-level ${CONFIG_ZSTD_COMP_LVL}"
    fi
    if [[ $comp_type = "gzip" ]]; then
        buf=`grep CONFIG_GZIP_SFS_ .config`
        eval "$buf"
        comp_option="-Xcompression-level ${CONFIG_GZIP_SFS_COMP_LVL} -Xwindow-size ${CONFIG_GZIP_SFS_WIN_SIZE}"
    fi
    if [[ $comp_type = "lz4" ]]; then
        buf=`grep CONFIG_LZ4_HIGH_COMP .config`
        eval "$buf"
        if [[ $CONFIG_LZ4_HIGH_COMP = "y" ]]; then
            comp_option="-Xhc"
        fi
    fi
fi
buf=`grep CONFIG_USE_CUSTOM_USERNAME .config`
eval "$buf"
if [[ $CONFIG_USE_CUSTOM_USERNAME = "y" ]]; then
    buf=`grep CONFIG_CUSTOM_USERNAME .config | sed -e 's/CONFIG_CUSTOM_USERNAME/username/g' `
    eval "$buf"
fi
buf=`grep CONFIG_USE_CUSTOM_PASSWD .config`
eval "$buf"
if [[ $CONFIG_USE_CUSTOM_PASSWD = "y" ]]; then
    buf=`grep CONFIG_CUSTOM_PASSWD .config | sed -e 's/CONFIG_CUSTOM_PASSWD/password/g' `
    eval "$buf"
fi
buf=`grep CONFIG_CHANNEL_ .config | sed -e 's/=y//g' | sed -e 's/CONFIG_CHANNEL_/channel=/g'`
eval "${buf,,}"
if [[ $USE_CUSTOM_LANG = "true" ]]; then
    buf=`grep CONFIG_CUSTOM_LANGUAGE .config | sed -e 's/CONFIG_CUSTOM_LANGUAGE/language/g' `
    eval "$buf"
fi

echo build option : 
    [[ -n "${language}" ]] && echo "           Language : ${language}"
    [[ -n "${plymouth}"    ]] && echo "           Plymouth : ${plymouth}"
    [[ -n "${kernel}"      ]] && echo "             kernel : ${kernel}"
    [[ -n "${comp_type}"   ]] && echo " Compression method : ${comp_type}"
    [[ -n "${comp_option}" ]] && echo "Compression options : ${comp_option}"
    [[ -n "${username}"    ]] && echo "           Username : ${username}"
    [[ -n "${password}"    ]] && echo "           Password : ${password}"
    [[ -n "${channel}"     ]] && echo "            Channel : ${channel}"

if [[ ${USE_CUSTOM_LANG} = "true" ]]; then
    argument="${argument} -g ${language}" 
fi
if [[ ${plymouth} = true ]]; then
    argument="${argument} -b"
fi
if [[ -n ${comp_type} ]]; then
    argument="${argument} -c ${comp_type}"
fi
if [[ -n ${kernel} ]]; then
    argument="${argument} -k ${kernel}"
fi
if [[ -n "${username}" ]]; then
    argument="${argument} -u '${username}'"
fi
if [[ -n ${password} ]]; then
    argument="${argument} -p '${password}'"
fi
if [[ -n ${out_dir} ]]; then
    argument="${argument} -o '${out_dir}'"
fi
argument="-a ${build_arch}  --noconfirm  ${argument} ${channel}"
echo $argument > $1