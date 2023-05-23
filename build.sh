#!/usr/bin/env bash

set -e -E -u -o pipefail

#-- Define base vars --#
script_path="$(cd "$(dirname "$0")" || exit 1; pwd)"
template_dir="$script_path/profile_template"
channel_dir=""

#-- Load lib --#
# shellcheck source=./lib/parsearg.sh
source "${script_path}/lib/parsearg.sh"
# shellcheck source=./lib/common.sh
source "${script_path}/lib/common.sh"
# shellcheck source=./lib/msg.sh
source "${script_path}/lib/msg.sh"
# shellcheck source=./lib/make_prepare.sh
source "${script_path}/lib/make_prepare.sh"
# shellcheck source=./lib/make_profiledef.sh
source "${script_path}/lib/make_profiledef.sh"
# shellcheck source=./lib/template_parser.sh
source "${script_path}/lib/template_parser.sh"
# shellcheck source=./lib/list_parser.sh
source "${script_path}/lib/list_parser.sh"
# shellcheck source=./lib/make_packages.sh
source "${script_path}/lib/make_packages.sh"
# shellcheck source=./lib/make_bootloader.sh
source "${script_path}/lib/make_bootloader.sh"
# shellcheck source=./lib/make_airootfs.sh
source "${script_path}/lib/make_airootfs.sh"
# shellckeck source=./lib/make_alteriso_files.sh
source "${script_path}/lib/make_alteriso_files.sh"
# shellcheck source=./lib/exec_archiso.sh
source "${script_path}/lib/exec_archiso.sh"


#-- Load default --#
# shellcheck source=./default.conf
source "${script_path}/default.conf"

#-- Parse argument --#
_t="$(mktemp)"
parsearg "$@" 1> "$_t"
readarray -t _noflag < "$_t"
rm -f "$_t"
set -- "${_noflag[@]}"
unset _noflag _t

#-- Set channel dir --#
channel_dir="${1-""}"
if [[ -z "$channel_dir" ]]; then
    msg_err "Please specify channel directory"
    exit 1
fi

#-- Run functions --#
call_func make_prepare
call_func make_default
call_func make_parsed_vars
call_func make_profiledef
call_func make_packages
call_func make_aur_packages
call_func make_bootstrap_packages
call_func make_bootloader
call_func make_airootfs
call_func make_alteriso_files
#call_func exec_archiso

