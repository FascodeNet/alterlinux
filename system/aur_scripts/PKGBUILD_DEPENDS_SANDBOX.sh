#!/usr/bin/env bash
#
# kokkiemouse
# Twitter -> @kokkiemouse
#
# (c) 2019-2020 Fascode Network.
#
# Parses PKGBUILD and outputs the dependencies.
#

#set -e -u

cd "$(dirname $0)"

msg_error() {
    echo -e "${@}" >&2
}

if [[ 2 -gt $# ]];then
    msg_error "missing pkgbuild name or arch-pkgbuild-parser"
    exit 1
fi

source "/etc/makepkg.conf"

parser="${1}"
pkgbuild="${2}"

if [[ ! -f "${1}" || ! -f "${2}" ]]; then
    msg_error "The specified file does not exist."
    exit 1
fi

data_result=$(${1} -m -p ${2})
eval ${data_result}

data_result=$(${1} -p ${2})
eval ${data_result}

for pkg in ${depends[@]} ; do
    echo "${pkg}" | cut -d '>' -f1 | cut -d '=' -f1
done
