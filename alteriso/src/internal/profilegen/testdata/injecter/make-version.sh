#!/usr/bin/env bash
set -euo pipefail

source "$1"

__alteriso_profile_dir=$2
buildmode=$3
install_dir=alter
pacstrap_dir=$4/pacstrap
bootstrap_parent=$4/bootstrap
install_log=$4/install.log

mkdir -p "$pacstrap_dir" "$bootstrap_parent"
if [[ "$buildmode" == @("iso"|"netboot") ]]; then
    isofs_dir=$4/isofs
fi

install() {
    local destination="${!#}"
    printf '%s\n' "$destination" >>"$install_log"
    command install "$@"
}

_unshare() {
    "$@"
}

__alteriso_make_version
