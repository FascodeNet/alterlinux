#!/usr/bin/env bash
#
# kokkiemouse
# Twitter -> @kokkiemouse
#
# (c) 2019-2020 Fascode Network.
#
# Parses PKGBUILD and outputs the dependencies.
#

set -e -u
cd "$(dirname $0)"
if [[ 1 -gt $# ]];then
    echo "missing pkgbuild name"
    exit 1
fi
source "${1}"

for pkg in ${makedepends[@]} ${depends[@]}; do
    echo "${pkg}" | cut -d '>' -f1 | cut -d '=' -f1
done
