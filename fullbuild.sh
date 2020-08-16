#!/usr/bin/env bash

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && pwd )"

channnels=(
    "xfce"
    "lxde"
    "cinnamon"
    "i3"
)

architectures=(
    "x86_64"
    "i686"
)

locale_list=(
    "ja"
    "gl"
)

work_dir=temp
simulation=false
retry=5

all_channel=false

# Color echo
# usage: echo_color -b <backcolor> -t <textcolor> -d <decoration> [Text]
#
# Text Color
# 30 => Black
# 31 => Red
# 32 => Green
# 33 => Yellow
# 34 => Blue
# 35 => Magenta
# 36 => Cyan
# 37 => White
#
# Background color
# 40 => Black
# 41 => Red
# 42 => Green
# 43 => Yellow
# 44 => Blue
# 45 => Magenta
# 46 => Cyan
# 47 => White
#
# Text decoration
# You can specify multiple decorations with ;.
# 0 => All attributs off (ノーマル)
# 1 => Bold on (太字)
# 4 => Underscore (下線)
# 5 => Blink on (点滅)
# 7 => Reverse video on (色反転)
# 8 => Concealed on

echo_color() {
    local backcolor
    local textcolor
    local decotypes
    local echo_opts
    local arg
    local OPTIND
    local OPT

    echo_opts="-e"

    while getopts 'b:t:d:n' arg; do
        case "${arg}" in
            b) backcolor="${OPTARG}" ;;
            t) textcolor="${OPTARG}" ;;
            d) decotypes="${OPTARG}" ;;
            n) echo_opts="-n -e"     ;;
        esac
    done

    shift $((OPTIND - 1))

    echo ${echo_opts} "\e[$([[ -v backcolor ]] && echo -n "${backcolor}"; [[ -v textcolor ]] && echo -n ";${textcolor}"; [[ -v decotypes ]] && echo -n ";${decotypes}")m${*}\e[m"
}


# Show an INFO message
# $1: message string
_msg_info() {
    local echo_opts="-e"
    local arg
    local OPTIND
    local OPT
    while getopts 'n' arg; do
        case "${arg}" in
            n) echo_opts="${echo_opts} -n" ;;
        esac
    done
    shift $((OPTIND - 1))
    echo ${echo_opts} "$( echo_color -t '36' '[fullbuild.sh]')    $( echo_color -t '32' 'Info') ${*}"
}


# Show an Warning message
# $1: message string
_msg_warn() {
    local echo_opts="-e"
    local arg
    local OPTIND
    local OPT
    while getopts 'n' arg; do
        case "${arg}" in
            n) echo_opts="${echo_opts} -n" ;;
        esac
    done
    shift $((OPTIND - 1))
    echo ${echo_opts} "$( echo_color -t '36' '[fullbuild.sh]') $( echo_color -t '33' 'Warning') ${*}" >&2
}


# Show an debug message
# $1: message string
_msg_debug() {
    local echo_opts="-e"
    local arg
    local OPTIND
    local OPT
    while getopts 'n' arg; do
        case "${arg}" in
            n) echo_opts="${echo_opts} -n" ;;
        esac
    done
    shift $((OPTIND - 1))
    if [[ ${debug} = true ]]; then
        echo ${echo_opts} "$( echo_color -t '36' '[fullbuild.sh]')   $( echo_color -t '35' 'Debug') ${*}"
    fi
}


# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
_msg_error() {
    local echo_opts="-e"
    local arg
    local OPTIND
    local OPT
    local OPTARG
    while getopts 'n' arg; do
        case "${arg}" in
            n) echo_opts="${echo_opts} -n" ;;
        esac
    done
    shift $((OPTIND - 1))
    echo ${echo_opts} "$( echo_color -t '36' '[fullbuild.sh]')   $( echo_color -t '31' 'Error') ${1}" >&2
    if [[ -n "${2:-}" ]]; then
        exit ${2}
    fi
}



trap_exit() {
    local status=${?}
    echo
    _msg_error "fullbuild.sh has been killed by the user."
    exit ${status}
}


build() {
    local _exit_code=0

    options="${share_options} -a ${arch} -g ${lang} ${cha}"

    if [[ ! -e "${work_dir}/fullbuild.${cha}_${arch}_${lang}" ]]; then
        if [[ "${simulation}" = true ]]; then
            echo "build.sh ${share_options} -a ${arch} -g ${lang} ${cha}"
            _exit_code="${?}"
        else
            _msg_info "Build the ${lang} version of ${cha} on the ${arch} architecture."
            sudo bash ${script_path}/build.sh ${options}
            _exit_code="${?}"
        fi
        if [[ "${_exit_code}" == 0 ]]; then
            touch "${work_dir}/fullbuild.${cha}_${arch}_${lang}"
        else
            _msg_error "build.sh finished with exit code ${_exit_code}. Will try again."
        fi
    fi
    sudo pacman -Sccc --noconfirm > /dev/null 2>&1
}

_help() {
    echo "usage ${0} [options]"
    echo
    echo " General options:"
    echo "    -a <options>       Set other options in build.sh"
    echo "    -c                 Build all channel (DO NOT specify the channel !!)"
    echo "    -d                 Use the default build.sh arguments. (${default_options})"
    echo "    -g                 Use gitversion."
    echo "    -h                 This help message."
    echo "    -m <architecture>  Set the architecture to build."
    echo "    -r <interer>       Set the number of retries."
    echo "                       Defalut: ${retry}"
    echo "    -s                 Enable simulation mode."
    echo "    -t                 Build the tarball as well."
    echo
    echo "!! WARNING !!"
    echo "Do not set channel or architecture with -a."
    echo "Be sure to enclose the build.sh argument with '' to avoid mixing it with the fullbuild.sh argument."
    echo "Example: ${0} -a '-b -k zen'"
}


share_options="--noconfirm"
default_options="-b -l -u alter -p alter"

while getopts 'a:dghr:sct' arg; do
    case "${arg}" in
        a) share_options="${share_options} ${OPTARG}" ;;
        c) all_channel=true ;;
        d) share_options="${share_options} ${default_options}" ;;
        m) architectures=(${OPTARG}) ;;
        g) 
            if [[ ! -d "${script_path}/.git" ]]; then
                _msg_error "There is no git directory. You need to use git clone to use this feature."
                exit 1
            else
                share_options="${share_options} --gitversion"
            fi
            ;;
        s) simulation=true;;
        r) retry="${OPTARG}" ;;
        t) share_options="${share_options} --tarball" ;;
        h) _help ; exit 0 ;;
        *) _help ; exit 1 ;;
    esac
done
shift $((OPTIND - 1))


if [[ "${all_channel}" = true  ]]; then
    if [[ -n "${*}" ]]; then
        _msg_error "Do not specify the channel." "1"
    else    
        channnels=($("${script_path}/build.sh" --channellist))
    fi
elif [[ -n "${*}" ]]; then
    channnels=(${@})
fi

_msg_info "Options: ${share_options}"
_msg_info "Press Enter to continue or Ctrl + C to cancel."
read


trap 'trap_exit' 1 2 3 15

if [[ ! -d "${work_dir}" ]]; then
    mkdir -p "${work_dir}"
fi

for cha in ${channnels[@]}; do
    for arch in ${architectures[@]}; do
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
    _msg_info "All editions have been built"
fi
