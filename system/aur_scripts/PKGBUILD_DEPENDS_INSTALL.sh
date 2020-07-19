#!/usr/bin/env bash
#
# kokkiemouse
# Twitter -> @kokkiemouse
#
# (c) 2019-2020 Fascode Network.
#
# Install the AUR package dependency.
#

set -e -u 
airootfs_path="$(readlink -f ${2})"
pacman_conf_path="$(readlink -f ${1})"
cd $(dirname "${0}")
script_path="$(readlink -f ${0%/*})"
if [ 3 -gt ${#} ];then
    echo "Error !"
    echo "You must set option."
    echo "PKGBUILD_DEPENDS_INSTALL.sh [pacman_conf] [airootfs] [packages.....]"
    exit 1
fi
shift 2
for _aur_pkg in ${*}; do
    pkgbuild_data=$("${script_path}/PKGBUILD_DEPENDS_SANDBOX.sh" "${airootfs_path}/aurbuild_temp/${_aur_pkg}/PKGBUILD")
    unshare --fork --pid pacman -r "${airootfs_path}" --config "${pacman_conf_path}" -Syu --needed --noconfirm  ${pkgbuild_data}
done