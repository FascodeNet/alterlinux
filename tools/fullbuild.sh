#!/usr/bin/env bash

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"

channnels=(
    "xfce"
#   "xfce-pro"
    "lxde"
    "cinnamon"
    "i3"
#   "gnome"
)

architectures=("x86_64" "i686")
locale_list=("ja" "en")
share_options=()
default_options=("--boot-splash" "--cleanup" "--user" "alter" "--password" "alter")

work_dir="${script_path}/work"
simulation=false
retry=5

remove_cache=false
all_channel=false
customized_work=false

# Show an INFO message
# $1: message string
msg_info() {
    local _msg_opts="-a fullbuilid -s 5"
    if [[ "${1}" = "-n" ]]; then
        _msg_opts="${_msg_opts} -o -n"
        shift 1
    fi
    "${script_path}/tools/msg.sh" ${_msg_opts} info "${1}"
}

# Show an Warning message
# $1: message string
msg_warn() {
    local _msg_opts="-a fullbuilid -s 5"
    if [[ "${1}" = "-n" ]]; then
        _msg_opts="${_msg_opts} -o -n"
        shift 1
    fi
    "${script_path}/tools/msg.sh" ${_msg_opts} warn "${1}"
}

# Show an debug message
# $1: message string
msg_debug() {
    if [[ "${debug}" = true ]]; then
        local _msg_opts="-a fullbuilid -s 5"
        if [[ "${1}" = "-n" ]]; then
            _msg_opts="${_msg_opts} -o -n"
            shift 1
        fi
        "${script_path}/tools/msg.sh" ${_msg_opts} debug "${1}"
    fi
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
msg_error() {
    local _msg_opts="-a fullbuilid -s 5"
    if [[ "${1}" = "-n" ]]; then
        _msg_opts="${_msg_opts} -o -n"
        shift 1
    fi
    "${script_path}/tools/msg.sh" ${_msg_opts} error "${1}"
    if [[ -n "${2:-}" ]]; then
        exit ${2}
    fi
}


trap_exit() {
    local status=${?}
    echo
    msg_error "fullbuild.sh has been killed by the user."
    exit ${status}
}


build() {
    local _exit_code=0 _options=("${share_options[@]}")

    _options+=("--arch" "${arch}" "--lang" "${lang}" "--" "${cha}")

    if [[ "${simulation}" = false ]] && [[ "${remove_cache}" = true ]]; then
        sudo pacman -Sccc --noconfirm
    fi

    if [[ ! -e "${fullbuild_dir}/fullbuild.${cha}_${arch}_${lang}" ]]; then
        if [[ "${simulation}" = true ]]; then
            echo "sudo bash build.sh ${_options[*]}"
            _exit_code="${?}"
        else
            msg_info "Build the ${lang} version of ${cha} on the ${arch} architecture."
            sudo bash "${script_path}/build.sh" "${_options[@]}"
            _exit_code="${?}"
            if [[ "${_exit_code}" = 0 ]]; then
                touch "${fullbuild_dir}/fullbuild.${cha}_${arch}_${lang}"
            else
                msg_error "build.sh finished with exit code ${_exit_code}. Will try again."
            fi
        fi
    fi
}

_help() {
    echo "usage ${0} [options] [channel]"
    echo
    echo " General options:"
    echo "    -a <options>       Set other options in build.sh"
    echo "    -c                 Build all channel (DO NOT specify the channel !!)"
    echo "    -d                 Use the default build.sh arguments. (${[default_options[*]})"
    echo "    -g                 Use gitversion"
    echo "    -h | --help        This help message"
    echo "    -l <locale>        Set the locale to build"
    echo "    -m <architecture>  Set the architecture to build"
    echo "    -r <interer>       Set the number of retries"
    echo "                       Defalut: ${retry}"
    echo "    -s                 Enable simulation mode"
    echo "    -t                 Build the tarball as well"
    echo "    -w <dir>           Set the work dir"
    echo
    echo "    --remove-cache     Clear cache for all packages on every build"
    echo
    echo " !! WARNING !!"
    echo " Do not set channel or architecture with -a."
    echo " Be sure to enclose the build.sh argument with '' to avoid mixing it with the fullbuild.sh argument."
    echo " Example: ${0} -a '-b -k zen'"
    echo
    echo "Run \"build.sh -h\" for channel details."
    echo -n " Channel: "
    "${script_path}/tools/channel.sh" show
}

share_options+=("--noconfirm")

# Parse options
ARGUMENT="${@}"
OPTS="a:dghr:sctm:l:w:"
OPTL="help,remove-cache"
if ! OPT=$(getopt -o ${OPTS} -l ${OPTL} -- ${ARGUMENT}); then
    exit 1
fi
eval set -- "${OPT}"
unset OPT OPTS OPTL

while true; do
    case ${1} in
        -a)
            share_options+=(${2})
            shift 2
            ;;
        -c)
            all_channel=true
            shift 1
            ;;
        -d)
            share_options+=("${default_options[@]}")
            shift 1
            ;;
        -m)
            architectures=(${2})
            shift 2
            ;;
        -g)
            if [[ ! -d "${script_path}/.git" ]]; then
                msg_error "There is no git directory. You need to use git clone to use this feature."
                exit 1
            else
                share_options+=("--gitversion")
            fi
            shift 1
            ;;
        -s)
            simulation=true
            shift 1
            ;;
        -r)
            retry="${2}"
            shift 2
            ;;
        -t)
            share_options+=("--tarball")
            ;;
        -l)
            locale_list=(${2})
            shift 2
            ;;
        -w)
            work_dir="${2}"
            customized_work=true
            shift 2
            ;;
        -h | --help)
            shift 1
            _help
            exit 0
            ;;
        --remove-cache)
            remove_cache=true
            shift 1
            ;;
        --)
            shift 1
            break
            ;;
        *)
            shift 1
            _help
            exit 1 
            ;;
    esac
done


if [[ "${all_channel}" = true  ]]; then
    if [[ -n "${*}" ]]; then
        msg_error "Do not specify the channel." "1"
    else
        channnels=($("${script_path}/tools/channel.sh" -b show))
    fi
elif [[ -n "${*}" ]]; then
    channnels=(${@})
fi

if [[ "${simulation}" = true ]]; then
    retry=1
fi

if [[ "${customized_work}" = false ]]; then
    work_dir="$(
        source "${script_path}/default.conf"
        if [[ -f "${script_path}/custom.conf" ]]; then
            source "${script_path}/custom.conf"
        fi
        if [[ "${work_dir:0:1}" = "/" ]]; then
            echo -n "${work_dir}"
        else
            echo -n "${script_path}/${work_dir}"
        fi
    )"
fi

if [[ ! -d "${work_dir}" ]]; then
    mkdir -p "${work_dir}"
fi

fullbuild_dir="${work_dir}/fullbuild"

share_options+=("--work" "${work_dir}")

msg_info "Options: ${share_options[*]}"
msg_info "Press Enter to continue or Ctrl + C to cancel."
read


trap 'trap_exit' 1 2 3 15

if [[ "${simulation}" = false ]]; then
    msg_info "Update the package database."
    sudo pacman -Syy
fi

for arch in ${architectures[@]}; do
    for cha in ${channnels[@]}; do
        for lang in ${locale_list[@]}; do
            for i in $(seq 1 ${retry}); do
                if [[ -n $(cat "${script_path}/channels/${cha}/architecture" | grep -h -v ^'#' | grep -x "${arch}") ]]; then
                    build
                fi
            done
        done
    done
done


if [[ "${simulation}" = false ]]; then
    msg_info "All editions have been built"
fi
