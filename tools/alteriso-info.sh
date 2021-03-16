#!/usr/bin/env bash
script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
tools_dir="${script_path}/tools"

_help() {
    echo "usage ${0} [options]"
    echo
    echo "Scripts that generate alteriso-info" 
    echo
    echo " General options:"
    echo "    -a | --arch         [str]      Specify the architecture"
    echo "    -b | --boot-splash  [bool]     Set plymouth status (true or false)"
    echo "    -c | --channel      [str]      Specify the channel"
    echo "    -d | --developer    [str]      Specify the developer"
    echo "    -k | --kernel       [srt]      Specify the kernel name"
    echo "    -o | --os-name      [str]      Specify the application name"
    echo "    -p | --password     [str]      Specify the user password for livecd"
    echo "    -u | --username     [str]      Specify the user name for livecd"
    echo "    -v | --version      [str]      Specity the iso version"
    echo "    -h | --help                    This help message"
}

# Parse options
ARGUMENT="${@}"
opt_short="a:b:c:d:k:o:p:u:v:h"
opt_long="arch:,boot-splash:,channel:,developer:,kernel:,os-name:,password:,username:,version:,help"
OPT=$(getopt -o ${opt_short} -l ${opt_long} -- ${ARGUMENT})
[[ ${?} != 0 ]] && exit 1

eval set -- "${OPT}"
unset OPT opt_short opt_long

while true; do
    case ${1} in
        -a | --arch)
            arch="${2}"
            shift 2
            ;;
        -b | --boot-splash)
            if [[ "${2}" = true || "${2}" = false ]]; then
                boot_splash="${2}"
                shift 2
            else
                _help
                exit 1
            fi
            ;;
        -c | --channel)
            channel_name="${2}"
            shift 2
            ;;
        -d | --developer)
            iso_publisher="${2}"
            shift 2
            ;;
        -k | --kernel)
            kernel="${2}"
            shift 2
            ;;
        -o | --os-name)
            iso_application="${2}"
            shift 2
            ;;
        -p | --password)
            password="${2}"
            shift 2
            ;;
        -u | --username)
            username="${2}"
            shift 2
            ;;
        -v | --version)
            iso_version="${2}"
            shift 2
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

variable_list=(
    "arch"
    "boot_splash"
    "channel_name"
    "iso_publisher"
    "kernel"
    "iso_application"
    "password"
    "username"
    "iso_version"
)

for var in ${variable_list[@]}; do
    if [[ -z "$(eval echo '$'${var})" ]]; then
        echo "${var} is empty" >&2
        exit 1
    fi
done


# Get kernel info
eval $(bash "${tools_dir}/kernel.sh" -s -c "${channel_name}" -a "${arch}" get "${kernel}")


echo "Developer      : ${iso_publisher}"
echo "OS Name        : ${iso_application}"
echo "Architecture   : ${arch}"
echo "Version        : ${iso_version}"
echo "Channel   name : ${channel_name}"
echo "Live user name : ${username}"
echo "Live user pass : ${password}"
echo "Kernel    name : ${kernel}"
echo "Kernel    path : ${kernel_filename}"
if [[ "${boot_splash}" = true ]]; then
    echo "Plymouth       : Yes"
else
    echo "Plymouth       : No"
fi
