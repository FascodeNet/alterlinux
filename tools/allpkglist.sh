#!/usr/bin/env bash

set -eu

load_config() {
    local _file
    for _file in "${@}"; do
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
pkglist=()

# Parse options
OPTS="a:o:hs"
OPTL="arch:,out:,help,stdout,aur"
if ! OPT=$(getopt -o ${OPTS} -l ${OPTL} -- "${@}"); then
    exit 1
fi
eval set -- "${OPT}"
unset OPT OPTS OPTL

while true; do
    case "${1}" in
        -a | --arch)
            IFS=" " read -ra archs <<< "${2}"
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
    for _file in "${@}"; do
        [[ -f "${_file}" ]] && source "${_file}"
    done
    return 0
}

for arch in "${archs[@]}"; do
    for channel in $("${tools_dir}/channel.sh" show -a "${arch}" -b -d -k zen -f); do
        readarray -t modules < <(
            load_config "${script_path}/default.conf" "${script_path}/custom.conf"
            load_config "${channel}/config.any" "${channel}/config.${arch}"
            if [[ -n "${include_extra+SET}" ]]; then
                if [[ "${include_extra}" = true ]]; then
                    modules=("base" "share" "share-extra" "calamares" "zsh-powerline")
                else
                    modules=("base" "share")
                fi
            fi
            printf "%s\n" "${modules[@]}"
        )

        pkglist_opts=(-a "${arch}" -b -c "${channel}" -k zen -l en --line "${modules[@]}")

        if [[ "${stdout}" = true ]]; then
            readarray -O "${#pkglist[@]}" -t pkglist < <("${tools_dir}/pkglist.sh" "${pkglist_opts[@]}")
            [[ "${include_aur}" = true ]] && readarray -O "${#pkglist[@]}" -t pkglist < <("${tools_dir}/pkglist.sh" --aur "${pkglist_opts[@]}") || true
        else
            (
                "${tools_dir}/pkglist.sh" -d "${pkglist_opts[@]}"
                [[ "${include_aur}" = true ]] && "${tools_dir}/pkglist.sh" --aur -d "${pkglist_opts[@]}" || true
            ) 1> "${out_dir}/$(basename "${channel}").${arch}"
        fi
        
    done
done

if [[ "${stdout}" = true ]]; then
    readarray -t pkglist < <(printf "%s\n" "${pkglist[@]}" | sort |uniq)
    printf "%s\n" "${pkglist[@]}"
fi
