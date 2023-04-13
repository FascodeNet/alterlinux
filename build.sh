#!/usr/bin/env bash

#-- Define base vars --#
script_path="$(cd "$(dirname "$0")" || exit 1; pwd)"
channel_dir=""

#-- Load lib --#
# shellcheck source=./lib/parsearg.sh
source "${script_path}/lib/parsearg.sh"
# shellcheck source=./lib/msg.sh
source "${script_path}/lib/msg.sh"
# shellcheck source=./lib/make_profiledef.sh
source "${script_path}/lib/make_profiledef.sh"


#-- Load default --#
# shellcheck source=./default.conf
source "${script_path}/default.conf"

#-- Parse argument --#
readarray -t _noflag < <(parsearg "$@")
set -- "${_noflag[@]}"
unset _noflag

#-- Set channel dir --#
channel_dir="${1-""}"
if [[ -z "$channel_dir" ]]; then
    msg_err "Please specify channel directory"
    exit 1
fi

#-- Run functions --#


