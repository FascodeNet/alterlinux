#!/usr/bin/env bash

set -e

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
share_dir=""
noshare="true"

boot_splash=false
aur=false
pkgdir_name="packages"

arch=""
profile_dir=""
kernel=""
locale_name=""

#arch="x86_64"
#channel_dir="${script_path}/channels/xfce"
#kernel="zen"
#locale_name="en"

_help() {
    echo "usage ${0} [options] [command]"
    echo
    echo "Get a list of packages to install on that profile"
    echo
    echo " General options:"
    echo "    -a | --arch [arch]        Specify the architecture"
    echo "    -b | --boot-splash        Enable boot splash"
    echo "    -p | --profile            Specify the profile directory"
    echo "    -s | --share              Specify the share profile directory"
    echo "    -k | --kernel             Specify the kernel"
    echo "    -h | --help               This help message"
    echo "         --aur                AUR packages"
}

# Usage: getclm <number>
# 標準入力から値を受けとり、引数で指定された列を抽出します。
getclm() {
    echo "$(cat -)" | cut -d " " -f "${1}"
}

# Message functions
msg_error() {
    "${script_path}/scripts/msg.sh" -s "5" -a "pkglist.sh" -l "Error" -r "red" error "${1}"
}

msg_info() {
    "${script_path}/scripts/msg.sh" -s "5" -a "pkglist.sh" -l "Info" -r "green" error "${1}"
}

msg_debug() {
    "${script_path}/scripts/msg.sh" -s "5" -a "pkglist.sh" -l "Debug" -r "magenta" error "${1}"
}


# Parse options
ARGUMENT="${@}"
_opt_short="a:bp:s:k:l:h"
_opt_long="arch:,boot-splash,profile:,share:,kernel:,locale:,aur,help"
OPT=$(getopt -o ${_opt_short} -l ${_opt_long} -- ${ARGUMENT})
[[ ${?} != 0 ]] && exit 1

eval set -- "${OPT}"
unset OPT _opt_short _opt_long

while true; do
    case ${1} in
        -a | --arch)
            arch="${2}"
            shift 2
            ;;
        -b | --boot-splash)
            boot_splash=true
            shift 1
            ;;
        -p | --profile)
            profile_dir="${2}"
            shift 2
            ;;
        -s | --share)
            share_dir="${2}"
            noshare="false"
            shift 2
            ;;
        -k | --kernel)
            kernel="${2}"
            shift 2
            ;;
        -l | --locale)
            locale_name="${2}"
            shift 2
            ;;
        --aur)
            aur=true
            shift 1
            ;;
        -h | --help)
            _help
            exit 0
            ;;
        --)
            shift 1
            break
            ;;

    esac
done


if [[ -z "${arch}" ]]; then
    msg_error "Architecture not specified"
    exit 1
elif [[ -z "${profile_dir}" ]]; then
    msg_error "Profile directory not specified"
    exit 1
elif [[ -z "${kernel}" ]]; then
    msg_error "kernel not specified"
    exit 1
elif [[ -z "${locale_name}" ]]; then
    msg_error "Locale not specified"
    exit 1
fi


if [[ "${aur}" = true ]]; then
    pkgdir_name="packages_aur"
else
    pkgdir_name="packages"
fi

set +e


#-- Detect package list to load --#
# Add the files for each profile to the list of files to read.

if [[ "${noshare}" = "false" ]]; then
    
    _loadfilelist=(
        # share packages
        $(ls ${share_dir}/${pkgdir_name}.${arch}/*.${arch} 2> /dev/null)
        "${share_dir}/${pkgdir_name}.${arch}/lang/${locale_name}.${arch}"
        # profile packages
        $(ls ${profile_dir}/${pkgdir_name}.${arch}/*.${arch} 2> /dev/null)
        "${profile_dir}/${pkgdir_name}.${arch}/lang/${locale_name}.${arch}"
        # kernel packages
        "${share_dir}/${pkgdir_name}.${arch}/kernel/${kernel}.${arch}"
        "${profile_dir}/${pkgdir_name}.${arch}/kernel/${kernel}.${arch}"
    )
else    
    _loadfilelist=(
        # profile packages
        $(ls ${profile_dir}/${pkgdir_name}.${arch}/*.${arch} 2> /dev/null)
        "${profile_dir}/${pkgdir_name}.${arch}/lang/${locale_name}.${arch}"
        # kernel packages
        "${profile_dir}/${pkgdir_name}.${arch}/kernel/${kernel}.${arch}"
    )
fi

# Plymouth package list
if [[ "${boot_splash}" = true ]]; then
    if [[ "${noshare}" = "false" ]]; then
        _loadfilelist+=(
            $(ls ${share_dir}/${pkgdir_name}.${arch}/plymouth/*.${arch} 2> /dev/null)
            $(ls ${profile_dir}/${pkgdir_name}.${arch}/plymouth/*.${arch} 2> /dev/null)
        )
    else
        _loadfilelist+=(
            $(ls ${profile_dir}/${pkgdir_name}.${arch}/plymouth/*.${arch} 2> /dev/null)
        )
    fi
fi


#-- Read package list --#
# Read the file and remove comments starting with # and add it to the list of packages to install.
for _file in ${_loadfilelist[@]}; do
    if [[ -f "${_file}" ]]; then
        msg_debug "Loaded package file ${_file}"
        _pkglist=( ${_pkglist[@]} "$(grep -h -v ^'#' ${_file})" )
    fi
done

#-- Read exclude list --#
# Exclude packages from the share exclusion list
if [[ "${noshare}" = "false" ]]; then
    _excludefile=(
        "${share_dir}/packages.${arch}/exclude"
        "${share_dir}/packages_aur.${arch}/exclude"
        "${profile_dir}/packages.${arch}/exclude"
        "${profile_dir}/packages_aur.${arch}/exclude"
    )
else
    _excludefile=(
        "${profile_dir}/packages.${arch}/exclude"
        "${profile_dir}/packages_aur.${arch}/exclude"
    )
fi

for _file in ${_excludefile[@]}; do
    if [[ -f "${_file}" ]]; then
        _excludelist=( ${_excludelist[@]} $(grep -h -v ^'#' "${_file}") )
    fi
done

#-- excludeに記述されたパッケージを除外 --#
# _pkglistを_subpkglistにコピーしexcludeのパッケージを除外し再代入
_subpkglist=(${_pkglist[@]})
unset _pkglist
for _pkg in ${_subpkglist[@]}; do
    # もし変数_pkgの値が配列_excludelistに含まれていなかったらpkglistに追加する
    if [[ ! $(printf '%s\n' "${_excludelist[@]}" | grep -qx "${_pkg}"; echo -n ${?} ) = 0 ]]; then
        _pkglist=(${_pkglist[@]} "${_pkg}")
    fi
done
unset _subpkglist

#-- excludeされたパッケージを表示 --#
if [[ -n "${_excludelist[*]}" ]]; then
    msg_debug "The following packages have been removed from the installation list."
    msg_debug "Excluded packages: ${_excludelist[*]}"
fi

# Sort the list of packages in abc order.
_pkglist=($(for _pkg in ${_pkglist[@]}; do echo "${_pkg}"; done | sort | perl -pe 's/\n/ /g'))

echo "${_pkglist[@]}" >&1
