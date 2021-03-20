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
    echo "    -a | --arch               Specify the architecture"
    echo "    -o | --out                Specify the output dir"
    echo "    -s | --stdout             Output to stdout (Ignore -o)"
    echo "    -h | --help               This help message"
    echo "         --aur                Include aur package to the list"
}

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
tools_dir="${script_path}/tools"
out_dir=""
archs=("x86_64" "i686" "i486")
stdout=false
include_aur=false

# Parse options
ARGUMENT="${@}"
OPTS="a:o:hs"
OPTL="arch:,out:,help,stdout,aur"
if ! OPT=$(getopt -o ${OPTS} -l ${OPTL} -- ${ARGUMENT}); then
    exit 1
fi
eval set -- "${OPT}"
unset OPT OPTS OPTL

while true; do
    case "${1}" in
        -a | --arch)
            archs=(${2})
            shift 2
            ;;
        -o | --out)
            out_dir="${2}"
            shift 2
            ;;
        -s | --stdout)
            stdout=true
            shift 1
            ;;
        -h | --help)
            _help
            exit 0
            ;;
        --aur)
            include_aur=true
            shift 1
            ;;
        --)
            shift 1
            break
            ;;

    esac
done


if [[ -z "${out_dir}" ]] || [[ "${stdout}" = true ]]; then
    stdout=true
else
    mkdir -p "${out_dir}"
fi

load_config() {
    local _file
    for _file in ${@}; do
        if [[ -f "${_file}" ]]; then
            source "${_file}"
        fi
    done
}

for_module(){
    local module
    for module in ${modules[@]}; do
        eval $(echo ${@} | sed "s|{}|${module}|g")
    done
}

for arch in ${archs[@]}; do
    for channel in $("${tools_dir}/channel.sh" show -a "${arch}" -b -d -k zen -f); do
        modules=($(
            load_config "${script_path}/default.conf" "${script_path}/custom.conf"
            load_config "${channel_dir}/config.any" "${channel_dir}/config.${arch}"
            if [[ ! -z "${include_extra+SET}" ]]; then
                if [[ "${include_extra}" = true ]]; then
                    modules=("share" "share-extra")
                else
                    modules=("share")
                fi
            fi
            for module in ${modules[@]}; do
                dependent="${module_dir}/${module}/dependent"
                if [[ -f "${dependent}" ]]; then
                    modules+=($(grep -h -v ^'#' "${dependent}" | tr -d "\n" ))
                fi
            done
            unset module dependent
            modules=($(printf "%s\n" "${modules[@]}" | sort | uniq))
            for_module load_config "${module_dir}/{}/config.any" "${module_dir}/{}/config.${arch}"
            echo "${modules[@]}"
        ))

        pkglist_opts="-a ${arch} -b -c ${channel%/} -k zen -l en --line ${modules[*]}"

        if [[ "${stdout}" = true ]]; then
            pkglist+=($("${tools_dir}/pkglist.sh" ${pkglist_opts}))
            if [[ "${include_aur}" = true ]]; then
                pkglist+=($("${tools_dir}/pkglist.sh" --aur ${pkglist_opts}))
            fi
        else
            (
                "${tools_dir}/pkglist.sh" -d ${pkglist_opts}
                if [[ "${include_aur}" = true ]]; then
                    "${tools_dir}/pkglist.sh" --aur -d ${pkglist_opts}
                fi
            ) 1> "${out_dir}/$(basename "${channel}").${arch}"
        fi
        
    done
done

if [[ "${stdout}" = true ]]; then
    pkglist=($(printf "%s\n" "${pkglist[@]}" | sort |uniq))
    printf "%s\n" "${pkglist[@]}"
fi
