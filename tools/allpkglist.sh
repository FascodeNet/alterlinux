#!/usr/bin/env bash

set -e

_help() {
    echo "usage ${0} [options]"
    echo
    echo "Outputs the package list of all channels in one file"
    echo
    echo " General options:"
    echo "    -o | --out                Specify the output dir"
    echo "    -h | --help               This help message"
}

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
tools_dir="${script_path}/tools"
out_dir=""

# Parse options
ARGUMENT="${@}"
_opt_short="o:h"
_opt_long="out:,help"
OPT=$(getopt -o ${_opt_short} -l ${_opt_long} -- ${ARGUMENT})
[[ ${?} != 0 ]] && exit 1
eval set -- "${OPT}"
unset OPT _opt_short _opt_long

while true; do
    case "${1}" in
        -o | --out)
            out_dir="${2}"
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

if [[ -z "${out_dir}" ]]; then  
    echo "Please specify the output destination directory." >&2
    exit 1
fi

for arch in "x86_64" "i686" "i486"; do
    for channel in $("${tools_dir}/channel.sh" show -a "${arch}" -b -d -k zen -f); do
        "${tools_dir}/pkglist.sh" -a "${arch}" -b -c "${channel}" -k zen -l en --line 1> "${out_dir}/$(basename "${channel}").${arch}"
    done
done
