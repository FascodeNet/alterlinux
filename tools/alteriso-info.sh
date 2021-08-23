#!/usr/bin/env bash
script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
tools_dir="${script_path}/tools"
modules=()

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
    echo "    -k | --kernel       [str]      Specify the kernel name"
    echo "    -m | --module       [str]      Specity the module (Separated by \",\")"
    echo "    -o | --os-name      [str]      Specify the application name"
    echo "    -p | --password     [str]      Specify the user password for livecd"
    echo "    -u | --username     [str]      Specify the user name for livecd"
    echo "    -v | --version      [str]      Specity the iso version"
    echo "    -h | --help                    This help message"
}

# Parse options
OPTS="a:b:c:d:k:m:o:p:u:v:h"
OPTL="arch:,boot-splash:,channel:,developer:,kernel:,module:,os-name:,password:,username:,version:,help"
if ! OPT="$(getopt -o "${OPTS}" -l "${OPTL}" -- "${@}")"; then
    exit 1
fi

eval set -- "${OPT}"
unset OPT OPTS OPTL

while true; do
    case "${1}" in
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
        -m | --module)
            readarray -t -O "${#modules[@]}" modules < <(echo "${2}" | tr "," "\n")
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

# Check values
variable_list=( "arch" "boot_splash" "channel_name" "iso_publisher" "kernel" "iso_application" "password" "username" "iso_version")

error=false
for var in "${variable_list[@]}"; do
    if [[ -z "$(eval echo "\$${var}")" ]]; then
        echo "${var} is empty" >&2
        error=true
    fi
done
[[ "${error}" = true ]] && exit 1
unset error

# Get kernel info
eval "$(bash "${tools_dir}/kernel.sh" -s -c "${channel_name}" -a "${arch}" get "${kernel}")"

echo "Developer      : ${iso_publisher}"
echo "OS Name        : ${iso_application}"
echo "Architecture   : ${arch}"
echo "Version        : ${iso_version}"
echo "Channel   name : ${channel_name}"
echo "Live user name : ${username}"
echo "Live user pass : ${password}"
echo "Kernel    name : ${kernel}"
echo "Kernel    path : ${kernel_filename}"
[[ "${#modules[@]}" != 0 ]] && echo "Loaded modules : ${modules[*]}"
if [[ "${boot_splash}" = true ]]; then
    echo "Plymouth       : Yes"
else
    echo "Plymouth       : No"
fi
