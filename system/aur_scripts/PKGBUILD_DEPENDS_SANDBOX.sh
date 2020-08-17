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
if [[ 2 -gt $# ]];then
    echo "missing pkgbuild name or arch-pkgbuild-parser"
    exit 1
fi
source "/etc/makepkg.conf"

data_result=`${1} -m -p ${2}`
eval ${data_result}
for pkg in ${makedepends[@]} ${depends[@]}; do
    echo "${pkg}" | cut -d '>' -f1 | cut -d '=' -f1
done
