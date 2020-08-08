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
pkgbuild_data=$(cat $1)
eval ${pkgbuild_data}
echo ${makedepends[@]}
echo ${depends[@]}
