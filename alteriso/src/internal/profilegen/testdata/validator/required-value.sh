#!/usr/bin/env bash
set -euo pipefail

__alteriso_validators=()
__alteriso_add_validator() { __alteriso_validators+=("$1"); }
__alteriso_profiledef_username() { :; }
__alteriso_profiledef_kernelname() { :; }

source "$1"

[[ ${#__alteriso_validators[@]} -eq 1 ]]
"${__alteriso_validators[0]}"
