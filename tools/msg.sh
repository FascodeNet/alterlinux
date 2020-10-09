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
output="stdout"

_help() {
    echo "usage ${0} [option] [type] [message]"
    echo
    echo "Display a message with a colored app name and message type label"
    echo
    echo " General type:"
    echo "    info                                  General message"
    echo "    warn                                  Warning message"
    echo "    error                                 Error message"
    echo "    debug                                 Debug message"
    echo
    echo " General options:"
    echo "    -a | --appname [name]                 Specify the app name"
    echo "    -c | --chr     [character]            Specify the character to adjust the label"
    echo "    -l | --label   [label]                Specify the label"
    echo "    -n | --nocolor                        No output colored output"
    echo "    -o | --option  [option]               Specify echo options"
    echo "    -s | --space   [number]               Specifies the label space"
    echo "    -x | --bash-debug                     Enables output bash debugging"
    echo "    -h | --help                           This help message"
    echo
    #echo "         --labelcolor                     Specify the color of label"
    echo "         --nolabel                        Do not output label"
    echo "         --noappname                      Do not output app name"
    echo "         --noadjust                       Do not adjust the width of the label"
}


# Parse options
ARGUMENT="${@}"
_opt_short="a:c:l:no:s:xh-:"
_opt_long="appname:,chr:,label:,nocolor,option:,space:,bash-debug,help,nolabel,noappname,noadjust"
OPT=$(getopt -o ${_opt_short} -l ${_opt_long} -- ${ARGUMENT})
[[ ${?} != 0 ]] && exit 1

eval set -- "${OPT}"
unset OPT _opt_short _opt_long

while true; do
  case ${1} in
        -a | --appname)
            appname="${2}"
            shift 2
            ;;
        -c | --chr)
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
        -o | --option)
            echo_opts="${2}"
            shift 2
            ;;
        -s | --spade)
            label_space="${2}"
            shift 2
            ;;
        -x | --bash-debug)
            bash_debug=true
            shift 1
            set -xv
            ;;
        -h |  --help)
            _help
            shift 1
            exit 0
            ;;
        --nolabel)
            nolabel=true
            shift 1
            ;;
        --noappname)
            noappname=true
            shift 1
            ;;
        --noadjust)
            noadjust=true
            shift 1
            ;;
        --)
            shift
            break
            ;;
        *)
            _help
            shift 1
            exit 1
            ;;
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
        output="stdout"
        [[ "${customized_label}" = false ]] && msg_label="Info"
        shift 1
        ;;
    "warn")
        msg_type="warn"
        textcolor="33"
        output="stdout"
        [[ "${customized_label}" = false ]] && msg_label="Warning"
        shift 1
        ;;
    "debug")
        msg_type="debug"
        textcolor="35"
        output="stdout"
        [[ "${customized_label}" = false ]] && msg_label="Debug"
        shift 1
        ;;
    "error")
        msg_type="error"
        textcolor="31"
        output="stderr"
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

full_message="$(echo_appname)$(echo_type)$(echo_message)"

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
