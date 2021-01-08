#!/usr/bin/env bash

set -e

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"

msg_type="info"
echo_opts=""
bash_debug=false
nocolor=false


# appname
appname="msg.sh"
noappname=false

# main text
message=""
textcolor="white"
customized_text_color=false
output="stdout"
customized_output=false

# label
msg_label=""
label_space="7"
nolabel=false
customized_label=false
customized_label_color=false
labelcolor=""
adjust_chr=" "
noadjust=false


_help() {
    echo "usage ${0} [option] [type] [message]"
    echo
    echo "Display a message with a colored app name and message type label"
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
    echo "    -l [label]                Specify the label"
    echo "    -n | --nocolor            No output colored output"
    echo "    -o [option]               Specify echo options"
    echo "    -p [output]               Specify the output destination"
    echo "                              standard output: stdout"
    echo "                              error output   : stderr"
    echo "    -r [color]                Specify the color of label"
    echo "    -s [number]               Specifies the label space"
    echo "    -t [color]                Specify the color of text"
    echo "    -x | --bash-debug         Enables output bash debugging"
    echo "    -h | --help               This help message"
    echo
    echo "         --nolabel            Do not output label"
    echo "         --noappname          Do not output app name"
    echo "         --noadjust           Do not adjust the width of the label"
}

# text [-b/-c color/-f/-l/]
# -b: 太字, -f: 点滅, -l: 下線
text() {
    local OPTIND OPTARG _arg _textcolor _decotypes="" _message
    while getopts "c:bfl" _arg; do
        case "${_arg}" in
            c)
                case "${OPTARG}" in
                    "black")
                        _textcolor="30"
                        ;;
                    "red")
                        _textcolor="31"
                        ;;
                    "green")
                        _textcolor="32"
                        ;;
                    "yellow")
                        _textcolor="33"
                        ;;
                    "blue")
                        _textcolor="34"
                        ;;
                    "magenta")
                        _textcolor="35"
                        ;;
                    "cyan")
                        _textcolor="36"
                        ;;
                    "white")
                        _textcolor="37"
                        ;;
                    *)
                        return 1
                        ;;
                esac
                ;;
            b)
                _decotypes="${_decotypes};1"
                ;;
            f)
                _decotypes="${_decotypes};5"
                ;;
            l)
                _decotypes="${_decotypes};4"
                ;;
        esac
    done
    shift "$((OPTIND - 1))"

    _message="${@}"
    if [[ "${nocolor}" = true ]]; then
        echo -ne "${@}"
    else
        echo -ne "\e[$([[ -v _textcolor ]] && echo -n ";${_textcolor}"; [[ -v _decotypes ]] && echo -n "${_decotypes}")m${_message}\e[m"
    fi
}

# Message functions
msg_error() {
    bash "${script_path}/tools/msg.sh" -a "msg.sh" error "${1}"
}


while getopts "a:c:l:no:p:r:s:t:xh-:" arg; do
  case "${arg}" in
        a)
            appname="${OPTARG}"
            ;;
        c)
            adjust_chr="${OPTARG}"
            ;;
        l)
            customized_label=true
            msg_label="${OPTARG}"
            ;;
        n)
            nocolor=true
            ;;
        o)
            echo_opts="${OPTARG}"
            ;;
        p)
            output="${OPTARG}"
            customized_output=true
            ;;
        r)
            customized_label_color=true
            case "${OPTARG}" in
                "black" | "red" | "green" | "yellow" | "blue" | "magenta" | "cyan" | "white")
                    labelcolor="${OPTARG}"
                    ;;
                *)
                    msg_error "The wrong color."
                    exit 1
                    ;;
            esac
            ;;
        s)
            label_space="${OPTARG}"
            ;;
        t)
            customized_text_color=true
            case "${OPTARG}" in
                "black" | "red" | "green" | "yellow" | "blue" | "magenta" | "cyan" | "white")
                    textcolor="${OPTARG}"
                    ;;
                *)
                    msg_error "The wrong color."
                    exit 1
                    ;;
            esac
            ;;
        x)
            bash_debug=true
            set -xv
            ;;
        h)
            _help
            shift 1
            exit 0
            ;;
        -)
            case "${OPTARG}" in
                "nocolor")
                    nocolor=true
                    ;;
                "bash-debug")
                    bash_debug=true
                    set -xv
                    ;;
                "help")
                    _help
                    exit 0
                    ;;
                "nolabel")
                    nolabel=true
                    ;;
                "noappname")
                    noappname=true
                    ;;
                "noadjust")
                    noadjust=true
                    ;;
                *)
                    _help
                    exit 1
                    ;;
            esac
  esac
done

shift "$((OPTIND - 1))"

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

case "${1}" in
    "info")
        msg_type="type"
        [[ "${customized_output}"      = false ]] && output="stdout"
        [[ "${customized_label_color}" = false ]] && labelcolor="green"
        [[ "${customized_label}"       = false ]] && msg_label="Info"
        shift 1
        ;;
    "warn")
        msg_type="warn"
        [[ "${customized_output}"      = false ]] && output="stdout"
        [[ "${customized_label_color}" = false ]] && labelcolor="yellow"
        [[ "${customized_label}"       = false ]] && msg_label="Warning"
        shift 1
        ;;
    "debug")
        msg_type="debug"
        [[ "${customized_output}"      = false ]] && output="stdout"
        [[ "${customized_label_color}" = false ]] && labelcolor="magenta"
        [[ "${customized_label}"       = false ]] && msg_label="Debug"
        shift 1
        ;;
    "error")
        msg_type="error"
        [[ "${customized_output}"      = false ]] && output="stderr"
        [[ "${customized_label_color}" = false ]] && labelcolor="red"
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
    local i
    if [[ "${nolabel}" = false ]]; then
        if [[ "${noadjust}" = false ]]; then
            for i in $( seq 1 "$(( label_space - word_count))" ); do
                echo -ne "${adjust_chr}"
            done
        fi
        text -c "${labelcolor}" "${msg_label}"
    fi
}

echo_appname() {
    if [[ "${noappname}" = false ]]; then
        text -c "cyan" "[${appname}]"
    fi
}

# echo_message <message>
echo_message() {
    text -c "${textcolor}" "${1}"
}

for count in $(seq "1" "$(echo -ne "${message}\n" | wc -l)"); do
    _message="$(echo -ne "${message}\n" | head -n "${count}" | tail -n 1 )"
    full_message="$(echo_appname)$(echo_type) $(echo_message "${_message}")"
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
    unset _message
done
