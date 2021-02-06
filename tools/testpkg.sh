#!/usr/bin/env bash

group_list=($(curl -s https://archlinux.org/groups/ | grep "/groups/x86_64" | cut -d "/" -f 4))

function searchpkg(){
    if printf "%s\n" "${group_list[@]}" | grep -x "${1}" >/dev/null; then
        return 0
    fi
    #if pacman -Ssq "${1}" 2>/dev/null | grep -o "^${1}*\$" 1>/dev/null; then
    if [[ -n "$(curl -sL "https://archlinux.org/packages/search/json/?name=${1}" | jq -r '.results[]')" ]]; then
        return 0
    elif [[ -n "$(curl -sL "https://archlinux.org/packages/search/json/?q=${1}" | jq -r ".results[].provides[]")" ]]; then
        return 0
    elif [[ -n "$(curl -s https://repo.dyama.net/alter-stable/x86_64/ | grep '\./' | grep "pkg.tar" | sed "s|	||g" | cut -d '"' -f 2 | xargs -If basename f | grep "${1}")" ]]; then
        return 0
    else
        return 1
    fi
}

function trap_exit() {
    local status="${?}"
    exit "${status}"
}

trap 'trap_exit' 1 2 3 15

script_path="$( cd -P "$( dirname "$(readlink -f "$0")" )" && cd .. && pwd )"
packages="$("${script_path}/tools/allpkglist.sh" -s -a "x86_64")"
error=false

for pkg in ${packages[@]}; do
    if ! searchpkg "${pkg}"; then
        echo "${pkg} is not in the official repository." >&2
        error=true
    fi
done

if [[ "${error}" = true ]]; then
    exit 1
else
    exit 0
fi
