#!/usr/bin/env bash

set -e

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
module_dir="${script_path}/modules"
modules=()

boot_splash=false
pkgdir_name="packages"
line=false
debug=false
memtest86=false
nocolor=false

additional_exclude_pkg=()

arch=""
channel_dir=""
kernel=""
locale_name=""


_help() {
    echo "usage ${0} [options] [module 1] [module 2]..."
    echo
    echo "Get a list of packages to install on that channel"
    echo
    echo " General options:"
    echo "    -a | --arch [arch]        Specify the architecture"
    echo "    -b | --boot-splash        Enable boot splash"
    echo "    -c | --channel [dir]      Specify the channel directory"
    echo "    -d | --debug              Enable debug message"
    echo "    -e | --exclude [pkgs]     List of packages to be additionally excluded"
    echo "    -k | --kernel [kernel]    Specify the kernel"
    echo "    -l | --locale [locale]    Specify the locale"
    echo "    -m | --memtest86          Enable memtest86 package"
    echo "    -h | --help               This help message"
    echo "         --aur                AUR packages"
    echo "         --line               Line break the output"
}

# Execute command for each module
# It will be executed with {} replaced with the module name.
# for_module <command>
for_module(){ local module && for module in "${modules[@]}"; do eval "${@//"{}"/${module}}"; done; }

# Message functions
msg_common(){
    local _args=(-s "5" -a "pkglist.sh")
    [[ "${nocolor}" = true ]] && _args+=("--nocolor")
    "${script_path}/tools/msg.sh" "${_args[@]}" "${@}"
}

msg_error() {
    msg_common -l "Error" -r "red" -p "stderr" error "${1}" &
}

msg_info() {
    msg_common -l "Info" -r "green" -p "stderr" info "${1}" &
}

msg_debug() {
    if [[ "${debug}" = true ]]; then
        msg_common -l "Debug" -r "magenta" -p "stderr" debug "${1}" &
    fi
}


# Parse options
ARGUMENT=("${@}")
OPTS="a:bc:de:k:l:mh"
OPTL="arch:,boot-splash,channel:,debug,exclude:,kernel:,locale:,memtest86,aur,help,line,nocolor"
if ! OPT=$(getopt -o ${OPTS} -l ${OPTL} -- "${ARGUMENT[@]}"); then
    exit 1
fi

eval set -- "${OPT}"
unset OPT OPTS OPTL ARGUMENT

while true; do
    case "${1}" in
        -a | --arch)
            arch="${2}"
            shift 2
            ;;
        -b | --boot-splash)
            boot_splash=true
            shift 1
            ;;
        -c | --channel)
            channel_dir="${2}"
            shift 2
            ;;
        -d | --debug)
            debug=true
            shift 1
            ;;
        -e | --exclude)
            IFS=" " read -r -a additional_exclude_pkg <<< "${2}"
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
        -m | --memtest86)
            memtest86=true
            shift 1
            ;;
        --aur)
            pkgdir_name="packages_aur"
            shift 1
            ;;
        --line)
            line=true
            shift 1
            ;;
        -h | --help)
            _help
            exit 0
            ;;
        --nocolor)
            nocolor=true
            shift 1
            ;;
        --)
            shift 1
            break
            ;;

    esac
done

for module in "${@}"; do
    if "${script_path}/tools/module.sh" check "${module}"; then
        modules=("${@}")
    else
        msg_debug "Module ${module} was not found"
    fi
done

if [[ -z "${arch}" ]] || [[ "${arch}" = "" ]]; then
    msg_error "Architecture not specified"
    exit 1
elif [[ -z "${channel_dir}" ]] || [[ "${channel_dir}" = "" ]]; then
    msg_error "Channel directory not specified"
    exit 1
elif [[ -z "${kernel}" ]] || [[ "${kernel}" = "" ]]; then
    msg_error "kernel not specified"
    exit 1
elif [[ -z "${locale_name}" ]] || [[ "${locale_name}" = "" ]]; then
    msg_error "Locale not specified"
    exit 1
fi

set +e

get_filelist(){
    if [[ -d "${1}" ]]; then
        find "${1}" -mindepth 1 -name "*.${arch}" -type f -or -type l 2> /dev/null
    fi
}

#-- Detect package list to load --#
# Add the files for each channel to the list of files to read.
#readarray -t _loadfilelist < <(ls ${channel_dir}/${pkgdir_name}.${arch}/*.${arch} 2> /dev/null)
readarray -t _loadfilelist < <(get_filelist "${channel_dir}/${pkgdir_name}.${arch}")

_loadfilelist+=(
    "${channel_dir}/${pkgdir_name}.${arch}/lang/${locale_name}.${arch}"
    "${channel_dir}/${pkgdir_name}.${arch}/kernel/${kernel}.${arch}"
)

# module package list
for_module '_loadfilelist+=($(ls ${module_dir}/{}/${pkgdir_name}.${arch}/*.${arch} 2> /dev/null))'
for_module '_loadfilelist+=(${module_dir}/{}/${pkgdir_name}.${arch}/lang/${locale_name}.${arch})'
for_module '_loadfilelist+=(${module_dir}/{}/${pkgdir_name}.${arch}/kernel/${kernel}.${arch})'

# Plymouth package list
if [[ "${boot_splash}" = true ]]; then
    #readarray -t -O "${#_loadfilelist[@]}" _loadfilelist < <(ls ${channel_dir}/${pkgdir_name}.${arch}/plymouth/*.${arch} 2> /dev/null)
    readarray -t -O "${#_loadfilelist[@]}" _loadfilelist < <(get_filelist "${channel_dir}/${pkgdir_name}.${arch}/plymouth")
    for_module '_loadfilelist+=($(ls ${module_dir}/{}/${pkgdir_name}.${arch}/plymouth/*.${arch} 2> /dev/null))'
fi

# memtest86 package list
if [[ "${memtest86}" = true ]]; then
    #readarray -t -O "${#_loadfilelist[@]}" _loadfilelist < <(ls ${channel_dir}/${pkgdir_name}.${arch}/memtest86/*.${arch} 2> /dev/null)
    readarray -t -O "${#_loadfilelist[@]}" _loadfilelist < <(get_filelist "${channel_dir}/${pkgdir_name}.${arch}/memtest86")

    for_module '_loadfilelist+=($(ls ${module_dir}/{}/${pkgdir_name}.${arch}/memtest86/*.${arch} 2> /dev/null))'
fi

#-- Read package list --#
# Read the file and remove comments starting with # and add it to the list of packages to install.
_pkglist=()
for _file in "${_loadfilelist[@]}"; do
    if [[ -f "${_file}" ]]; then
        msg_debug "Loaded package file ${_file}"
        #_pkglist=( ${_pkglist[@]} "$(grep -h -v ^'#' ${_file})" )
        readarray -t -O "${#_pkglist[@]}" _pkglist < <(grep -h -v ^'#' "${_file}")
    else
        msg_debug "The file was not found ${_file}"
    fi
done

#-- Read exclude list --#
# Exclude packages from the share exclusion list
_excludefile=("${channel_dir}/packages.${arch}/exclude" "${channel_dir}/packages_aur.${arch}/exclude")
for_module '_excludefile+=("${module_dir}/{}/packages.${arch}/exclude" "${module_dir}/{}/packages_aur.${arch}/exclude")'

for _file in "${_excludefile[@]}"; do
    if [[ -f "${_file}" ]]; then
        #_excludelist+=($(grep -h -v ^'#' "${_file}") )
        readarray -t -O "${#_excludelist[@]}" _excludelist < <(grep -h -v ^'#' "${_file}")
    fi
done

#-- additional_exclude_pkg のパッケージを_excludelistに追加 --#
if (( "${#additional_exclude_pkg[@]}" >= 1 )); then
    _excludelist+=("${additional_exclude_pkg[@]}")
    msg_debug "Additional excluded packages: ${additional_exclude_pkg[*]}"
fi

#-- パッケージリストをソートし重複を削除 --#
#_pkglist=($(printf "%s\n" "${_pkglist[@]}" | sort | uniq | tr "\n" " "))
readarray -t _pkglist < <(printf "%s\n" "${_pkglist[@]}" | sort | uniq | grep -v ^$)

#-- excludeに記述されたパッケージを除外 --#
for _pkg in "${_excludelist[@]}"; do
    #_pkglist=($(printf "%s\n" "${_pkglist[@]}" | grep -xv "${_pkg}" | tr "\n" " "))
    readarray -t _pkglist < <(printf "%s\n" "${_pkglist[@]}" | grep -xv "${_pkg}")
done

#-- excludeされたパッケージを表示 --#
if (( "${#_excludelist[@]}" >= 1 )); then
    msg_debug "The following packages have been removed from the installation list."
    msg_debug "Excluded packages: ${_excludelist[*]}"
else
    msg_debug "No packages are excluded."
fi

wait

if [[ "${line}" = true ]]; then
    printf "%s\n" "${_pkglist[@]}"
else
    echo "${_pkglist[*]}" >&1
fi
