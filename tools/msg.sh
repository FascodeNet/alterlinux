#!/usr/bin/env bash

set -e

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"

appname="msg.sh"
bash_debug=false
nocolor=false
echo_opts=""
message=""
msg_type="info"
msg_label=""
label_space="7"
adjust_chr=" "
customized_label=false
customized_label_color=false
nolabel=false
noappname=false
noadjust=false
output="stdout"

_help() {
    echo "usage ${0} [option] [type] [message]"
    echo
    echo "Display a message with a colored app name and message type label"
    echo
    echo " General type:"
    echo "    info                             General message"
    echo "    warn                             Warning message"
    echo "    error                            Error message"
    echo "    debug                            Debug message"
    echo
    echo " General options:"
    echo "    -a | --appname     [name]        Specify the app name"
    echo "    -c | --adjust-chr  [character]   Specify the character to adjust the label"
    echo "    -l | --label       [label]       Specify the label."
    echo "    -n | --nocolor                   No output colored output"
    echo "    -o | --echo-opts   [option]      Specify echo options"
    echo "    -r | --label-color [color]       Specify the color of label"
    echo "    -s | --label-space [number]      Specifies the label space."
    echo "    -x | --bash-debug                Enables output bash debugging"
    echo "    -h | --help                      This help message"
    echo
    echo "         --nolabel                   Do not output label"
    echo "         --noappname                 Do not output app name"
    echo "         --noadjust                  Do not adjust the width of the label"
}

# Message functions
msg_error() {
    "${script_path}/tools/msg.sh" -a "msg.sh" error "${1}"
}


# Parse options
ARGUMENT="${*}"
_opt_short="a:c:l:no:r:s:xh"
_opt_long="nocolor,bash-debug,help,nolabel,noappname,noadjust,appname:,adjust-chr:,label:,echo-opts:,label-color:,label-space:"
OPT=$(getopt -uo ${_opt_short} -l ${_opt_long} -- "${ARGUMENT}")
[[ ${?} != 0 ]] && exit 1

eval set -- "${OPT}"
unset OPT _opt_short _opt_long

while true; do
    case "${1}" in
        -a | --appname)
            appname="${2}"
            shift 2
            ;;
        -c | --adjust-chr)
            adjust_chr="${2}"
            shift 2
            ;;
        -l | --label)
            customized_label=true
            msg_label="${2}"
            shift 2
            ;;
        -n | --nocolor)
            nocolor=true
            shift 1
            ;;
        -o | --echo-opts)
            echo_opts="${2}"
            shift 2
            ;;
        -r | --label-color)
            customized_label_color=true
            case "${2}" in
                "black")
                    labelcolor="30"
                    ;;
                "red")
                    labelcolor="31"
                    ;;
                "green")
                    labelcolor="32"
                    ;;
                "yellow")
                    labelcolor="33"
                    ;;
                "blue")
                    labelcolor="34"
                    ;;
                "magenta")
                    labelcolor="35"
                    ;;
                "cyan")
                    labelcolor="36"
                    ;;
                "white")
                    labelcolor="37"
                    ;;
                *)
                    msg_error "The wrong color."
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        -s | --label-space)
            label_space="${2}"
            shift 2
            ;;
        -x | --bash-debug)
            bash_debug=true
            set -xv
            shift 1
            ;;
        -h | --help)
            _help
            shift 1
            exit 0
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

# Color echo
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

case ${1} in
    "info")
        msg_type="type"
        output="stdout"
        [[ "${customized_label_color}" = false ]] && labelcolor="32"
        [[ "${customized_label}"       = false ]] && msg_label="Info"
        shift 1
        ;;
    "warn")
        msg_type="warn"
        output="stdout"
        [[ "${customized_label_color}" = false ]] && labelcolor="33"
        [[ "${customized_label}"       = false ]] && msg_label="Warning"
        shift 1
        ;;
    "debug")
        msg_type="debug"
        output="stdout"
        [[ "${customized_label_color}" = false ]] && labelcolor="35"
        [[ "${customized_label}"       = false ]] && msg_label="Debug"
        shift 1
        ;;
    "error")
        msg_type="error"
        output="stderr"
        [[ "${customized_label_color}" = false ]] && labelcolor="31"
        [[ "${customized_label}"       = false ]] && msg_label="Error"
        shift 1
        ;;
    "")
        msg_error "Please specify the message type"
        exit 1
        ;;
    *)
        msg_error "Unknown message type"
        exit 1
        ;;
esac

word_count="${#msg_label}"
message="${@}"

echo_type() {
    if [[ "${nolabel}" = false ]]; then
        if [[ "${noadjust}" = false ]]; then
            for i in $( seq 1 $(( ${label_space} - ${word_count})) ); do
                echo -ne "${adjust_chr}"
            done
        fi
        if [[ "${nocolor}" = false ]]; then
            echo -ne "\e[$([[ -v backcolor ]] && echo -n "${backcolor}"; [[ -v labelcolor ]] && echo -n ";${labelcolor}"; [[ -v decotypes ]] && echo -n ";${decotypes}")m${msg_label}\e[m "
        else
            echo -ne "${msg_label} "
        fi
    fi
}

echo_appname() {
    if [[ "${noappname}" = false ]]; then
        if [[ "${nocolor}" = false ]]; then
            echo -ne "\e[36m[${appname}]\e[m "
        else
            echo -ne "[${appname}] "
        fi
    fi
}


for count in $(seq "1" "$(echo -ne "${message}\n" | wc -l)"); do
    echo_message=$(echo -ne "${message}\n" |head -n "${count}" | tail -n 1 )
    full_message="$(echo_appname)$(echo_type)${echo_message}"
    case "${output}" in
        "stdout")
            echo ${echo_opts} "${full_message}" >&1
            ;;
        "stderr")
            echo ${echo_opts} "${full_message}" >&2
            ;;
        *)
            echo ${echo_opts} "${full_message}" > ${output}
            ;;
    esac
done
