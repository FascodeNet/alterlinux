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
nolabel=false
noappname=false
noadjust=false

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
    echo "    -a [name]                 Specify the app name"
    echo "    -c [character]            Specify the character to adjust the label"
    echo "    -l [label]                Specify the label."
    echo "    -n | --nocolor            No output colored output"
    echo "    -o [option]               Specify echo options"
    echo "    -s [number]               Specifies the label space."
    echo "    -x | --bash-debug         Enables output bash debugging"
    echo "    -h | --help               This help message"
    echo
    echo "         --nolabel            Do not output label"
    echo "         --noappname          Do not output app name"
    echo "         --noadjust           Do not adjust the width of the label"
}


while getopts "a:c:l:no:s:xh-:" arg; do
  case ${arg} in
        a) appname="${OPTARG}" ;;
        c) adjust_chr="${OPTARG}" ;;
        l) 
            customized_label=true
            msg_label="${OPTARG}"
            ;;
        n) nocolor=true ;;
        o) echo_opts="${OPTARG}" ;;
        s) label_space="${OPTARG}" ;;
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
                "nolabel") nolabel=true ;;
                "noappname") noappname=true ;;
                "noadjust") noadjust=true ;;
                *)
                    _help
                    exit 1
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
        [[ "${customized_label}" = false ]] && msg_label="Info"
        shift 1
        ;;
    "warn")
        msg_type="warn"
        textcolor="33"
        [[ "${customized_label}" = false ]] && msg_label="Warning"
        shift 1
        ;;
    "debug")
        msg_type="debug"
        textcolor="35"
        [[ "${customized_label}" = false ]] && msg_label="Debug"
        shift 1
        ;;
    "error")
        msg_type="error"
        textcolor="31"
        [[ "${customized_label}" = false ]] && msg_label="Error"
        shift 1
        ;;
    "")
        "${script_path}/tools/msg.sh" -a "msg.sh" error "Please specify the message type"
        exit 1
        ;;
    *)
        "${script_path}/tools/msg.sh" -a "msg.sh" error "Unknown message type"
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
            echo -ne "\e[$([[ -v backcolor ]] && echo -n "${backcolor}"; [[ -v textcolor ]] && echo -n ";${textcolor}"; [[ -v decotypes ]] && echo -n ";${decotypes}")m${msg_label}\e[m "
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

echo_message() {
    echo -ne "${message}\n"
}

echo ${echo_opts} "$(echo_appname)$(echo_type)$(echo_message)"
