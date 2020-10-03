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
label_width="7"

_help() {
    echo "usage ${0} [option] [type] [message]"
    echo
    echo "Outputs colored messages" 
    echo
    echo " General type:"
    echo "    info                      General message"
    echo "    warn                      Warning message"
    echo "    error                     Error message"
    echo "    debug                     Debug message"
    echo
    echo " General options:"
    echo "    -a                        Specify the app name"
    echo "    -n | --nocolor            No output colored output"
    echo "    -o                        Specify echo options"
    echo "    -x | --bash-debug         Enables output bash debugging"
    echo "    -h | --help               This help message"
}


while getopts "a:no:xh-:" arg; do
  case ${arg} in
        a) appname="${OPTARG}" ;;
        n) nocolor=true ;;
        o) echo_opts="${OPTARG}" ;;
        x)
            bash_debug=true
            set -xv
            ;;
        h)
            _help
            exit 0
            ;;
        -)
            case "${OPTARG}" in
                "nocolor") nocolor=true ;;
                "bash-debug")
                    bash_debug=true
                    set -xv
                    ;;
                "help") 
                    _help
                    exit 0
                    ;;
            esac
  esac
done

shift $((OPTIND - 1))

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
        textcolor="32"
        msg_label="Info"
        shift 1
        ;;
    "warn")
        msg_type="warn"
        textcolor="33"
        msg_label="Warning"
        shift 1
        ;;
    "debug")
        msg_type="debug"
        textcolor="35"
        msg_label="Debug"
        shift 1
        ;;
    "error")
        msg_type="error"
        textcolor="31"
        msg_label="Error"
        shift 1
        ;;
    "")
        "${script_path}/tools/msg.sh" -a "msg.sh" error "Please specify the message type"
        ;;
    *)
        "${script_path}/tools/msg.sh" -a "msg.sh" error "Unknown message type"
        ;;
esac

word_count="${#msg_label}"
message="${@}"

echo_type() {
    for i in $( seq 1 $(( ${label_width} - ${word_count} )) ); do
        echo -ne " "
    done
    if [[ "${nocolor}" = false ]]; then
        echo -ne "\e[$([[ -v backcolor ]] && echo -n "${backcolor}"; [[ -v textcolor ]] && echo -n ";${textcolor}"; [[ -v decotypes ]] && echo -n ";${decotypes}")m${msg_label}\e[m"
    else
        echo -ne "${msg_label}"
    fi
}

echo_appname() {
    if [[ "${nocolor}" = false ]]; then
        echo -ne "\e[36m[${appname}]\e[m"
    else
        echo -ne "[${appname}]"
    fi
}

echo ${echo_opts} "$(echo_appname) $(echo_type) ${message}"
