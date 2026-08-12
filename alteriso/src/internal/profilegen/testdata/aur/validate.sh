#!/usr/bin/env bash
set -euo pipefail

__alteriso_add_validator() { :; }
__alteriso_arch() { printf '%s\n' x86_64; }

source "$1"

__alteriso_profile_dir=$2
arch=x86_64
ALTERISO_AYAKA=$2/missing-ayaka
__alteriso_aur_validate
