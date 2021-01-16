#!/usr/bin/env bash

set -e

load_config() {
    local _file
    for _file in ${@}; do
        if [[ -f "${_file}" ]]; then
            source "${_file}"
        fi
    done
}

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
opt_short="o:h"
opt_long="out:,help"
OPT=$(getopt -o ${opt_short} -l ${opt_long} -- ${ARGUMENT})
[[ ${?} != 0 ]] && exit 1
eval set -- "${OPT}"
unset OPT opt_short opt_long

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


share_dir="${script_path}/channels/share"
extra_dir="${script_path}/channels/share-extra"

mkdir -p "${out_dir}"

for arch in "x86_64" "i686" "i486"; do
    for channel in $("${tools_dir}/channel.sh" show -a "${arch}" -b -d -k zen -f); do
    #for channel in "${script_path}/channels/releng"; do
        include_extra=$(
            load_config "${share_dir}/config.any" "${share_dir}/share/config.${arch}"
            load_config "${channel}/config.any" "${channel}/config.${arch}"
            if [[ "${include_extra}" = true ]]; then
                load_config "${extra_dir}/config.any" "${extra_dir}/share/config.${arch}"
            fi
            echo ${include_extra}
        )

        pkglist_opts="-a "${arch}" -b -c "${channel%/}" -k zen -l en --line"

        if [[ "${include_extra}" = true ]]; then
            pkglist_opts+=" -e"
        fi

        if [[ -z "${out_dir}" ]]; then  
            "${tools_dir}/pkglist.sh" ${pkglist_opts}
        else
            "${tools_dir}/pkglist.sh" ${pkglist_opts} 1> "${out_dir}/$(basename "${channel}").${arch}"
        fi
        
    done
done
