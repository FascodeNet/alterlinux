#!/usr/bin/env bash
set -euo pipefail

__alteriso_add_validator() { :; }
source "$1"
work_dir=$2
run_once_mode=base
touch "$work_dir/base.pre__make_packages"
__alteriso_aur_exit_trap_installed=y
trap '__alteriso_aur_cleanup_on_exit' EXIT
false
