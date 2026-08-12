#!/usr/bin/env bash
set -euo pipefail

source "$1"

__alteriso_add_validator first
__alteriso_add_validator second
__alteriso_add_validator first
printf '%s\n' "${__alteriso_validators[@]}"
