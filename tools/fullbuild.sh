#!/usr/bin/env bash

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"

channels=(
##  Current official channel
    "xfce"
    "i3"
    "plasma"

## Scheduled to discontinue distribution
    "lxde"
    "cinnamon"

## They are unstable channel
#   "xfce-pro"
#   "gnome"
#   "serene"
)

architectures=("x86_64" "i686")
locale_list=("ja" "en")
share_options=()
default_options=("--boot-splash" "--user" "alter" "--password" "alter" "--log")
failed=()
abort=false

work_dir="${script_path}/work"
out_dir="${script_path}/out"
simulation=false
retry=1

remove_cache=false
all_channel=false
customized_work=false
noconfirm=false

# Message common function
# msg_common [type] [-n] [string]
msg_common(){
    local _msg_opts=("-a" "fullbuild" "-s" "5") _type="${1}"
    shift 1
    [[ "${1}" = "-n" ]] && _msg_opts+=("-o" "-n") && shift 1
    [[ "${nocolor}"  = true ]] && _msg_opts+=("-n")
    _msg_opts+=("${_type}" "${@}")
    "${script_path}/tools/msg.sh" "${_msg_opts[@]}"
}

# Show an INFO message
# ${1}: message string
msg_info() { msg_common info "${@}"; }

# Show an Warning message
# ${1}: message string
msg_warn() { msg_common warn "${@}"; }

# Show an ERROR message then exit with status
# ${1}: message string
# ${2}: exit code number (with 0 does not exit)
msg_error() {
    msg_common error "${1}"
    [[ -n "${2:-}" ]] && exit "${2}"
    return 0
}


trap_exit() {
    local status="${?}"
    echo
    msg_error "fullbuild.sh has been killed by the user."
    exit "${status}"
}


build() {
    local _exit_code=0 _options=("${share_options[@]}")

    _options+=("--arch" "${arch}" "--lang" "${lang}" "--out" "${out_dir}/${cha}/${lang}" "${cha}")

    if [[ "${simulation}" = false ]] && [[ "${remove_cache}" = true ]]; then
        msg_info "Removing package cache for ${arch}"
        sudo rm -rf "${work_dir}/cache/${arch}"
    fi

    if [[ ! -e "${fullbuild_dir}/fullbuild.${cha}_${arch}_${lang}" ]]; then
        if [[ "${simulation}" = true ]]; then
            echo "sudo bash build.sh ${_options[*]}"
            _exit_code="${?}"
        else
            msg_info "Build the ${lang} version of ${cha} on the ${arch} architecture."
            sudo bash "${script_path}/build.sh" "${_options[@]}"
            _exit_code="${?}"
            if (( _exit_code == 0 )); then
                touch "${fullbuild_dir}/fullbuild.${cha}_${arch}_${lang}"
            elif (( "${retry_count}" == "${retry}" )); then
                msg_error "Failed to build (Exit code: ${_exit_code})"
                if [[ "${abort}" = true ]]; then
                    exit "${_exit_code}"
                else
                    failed+=("${cha}-${arch}-${lang}")
                fi
            else
                msg_error "build.sh finished with exit code ${_exit_code}. Will try again."
            fi
            
        fi
    else
        msg_info "Found: ${fullbuild_dir}/fullbuild.${cha}_${arch}_${lang}"
    fi
}

_help() {
    echo "usage ${0} [options] [channel]"
    echo
    echo " General options:"
    echo "    -a <options>       Set other options in build.sh"
    echo "    -c                 Build all channel (DO NOT specify the channel !!)"
    echo "    -d                 Use the default build.sh arguments. (${default_options[*]})"
    echo "    -e                 Exit the script when the build fails"
    echo "    -g                 Use gitversion"
    echo "    -h | --help        This help message"
    echo "    -l <locale>        Set the locale to build"
    echo "    -m <architecture>  Set the architecture to build"
    echo "    -o <dir>           Set the out dir"
    echo "    -r <interer>       Set the number of retries"
    echo "                       Defalut: ${retry}"
    echo "    -s                 Enable simulation mode"
    echo "    -t                 Build the tarball as well"
    echo "    -w <dir>           Set the work dir"
    echo
    echo "    --remove-cache     Clear cache for all packages on every build"
    echo "    --noconfirm        Run without confirmation"
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
ARGUMENT=("${@}")
OPTS=("a:" "d" "e" "g" "h" "r:" "s" "c" "t" "m:" "l:" "w:" "o:")
OPTL=("help" "remove-cache" "noconfirm")
if ! OPT=$(getopt -o "$(printf "%s," "${OPTS[@]}")" -l "$(printf "%s," "${OPTL[@]}")" --  "${ARGUMENT[@]}"); then
    exit 1
fi
eval set -- "${OPT}"
unset OPT OPTS OPTL ARGUMENT

while true; do
    case "${1}" in
        -a)
            IFS=" " read -r -a share_options <<< "${2}"
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
        -e)
            abort=true
            shift 1
            ;;
        -m)
            IFS=" " read -r -a architectures <<< "${2}"
            shift 2
            ;;
        -o)
            out_dir="${2}"
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
            IFS=" " read -r -a locale_list <<< "${2}"
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
        --noconfirm)
            noconfirm=true
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
        readarray -t channels < <("${script_path}/tools/channel.sh" -b show)
    fi
elif [[ -n "${*}" ]]; then
    channels=("${@}")
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

fullbuild_dir="${work_dir}/fullbuild"
mkdir -p "${fullbuild_dir}"

if [[ "$(find "${fullbuild_dir}" -maxdepth 1 -mindepth 1 -name "fullbuild.*" 2> /dev/null)" ]] && [[ "${noconfirm}" = false ]]; then
    msg_info "Do you want to reset lock files ? (y/N)"
    read -r -n 1 _yes_or_no
    echo
    if [[ "${_yes_or_no}" = "y" ]] || [[ "${_yes_or_no}" = "Y" ]]; then
        find "${fullbuild_dir}" -maxdepth 1 -mindepth 1 -name "fullbuild.*" -delete 2> /dev/null
    fi
fi


share_options+=("--work" "${work_dir}")
msg_info "Options: ${share_options[*]}"
if [[ "${noconfirm}" = false ]]; then
    msg_info "Press Enter to continue or Ctrl + C to cancel."
    read -r
fi


trap 'trap_exit' 1 2 3 15

for arch in "${architectures[@]}"; do
    for cha in "${channels[@]}"; do
        for lang in "${locale_list[@]}"; do
            for retry_count in $(seq 1 "${retry}"); do
                if grep -h -v ^'#' "${script_path}/channels/${cha}/architecture" | grep -x "${arch}" 1> /dev/null 2>&1; then
                    build
                fi
            done
        done
    done
done


if [[ "${simulation}" = false ]]; then
    if (( "${#failed[@]}" == 0 )); then
        msg_info "All editions have been built"
    else
        msg_error "Build of the following settings failed"
        printf " - %s\n" "${failed[@]}"
    fi
fi
