#!/usr/bin/env bash
set -euo pipefail

source "$1"

__alteriso_profiledef_arch() { printf '%s\n' i486; }
unset arch
__alteriso_arch
arch=x86_64
__alteriso_arch
