#!/usr/bin/env bash
set -euo pipefail

__alteriso_add_validator() { :; }
__alteriso_arch() { printf '%s\n' x86_64; }
source "$1"
__alteriso_profile_dir=$2
work_dir=$3
arch=x86_64
buildmode=iso
run_once_mode=iso
ALTERISO_AYAKA=$4
AYAKA_ARGS=$5
export ALTERISO_AYAKA AYAKA_ARGS
buildmode_pkg_list=(base)
_msg_info() { :; }
_msg_error() { printf '%s\n' "$1" >&2; return "${2:-1}"; }
__alteriso_aur_build_packages
