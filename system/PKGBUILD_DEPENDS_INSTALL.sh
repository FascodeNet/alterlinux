#!/usr/bin/env bash
#
# kokkiemouse
# Twitter -> @kokkiemouse
#
# (c) 2019-2020 Fascode Network.
#
set -e -u 
if [ 3 -gt $# ];then
    echo "Error !"
    echo "You must set option."
    echo "./PKGBUILD_DEPENDS_INSTALL.sh [mkalteriso] [airootfs] [packages.....]"
    exit 1
fi
mkalteriso_path=$1
airootfs_path=$2
shift 2
for _aur_pkg in ${*}; do
    
done