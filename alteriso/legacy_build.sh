#!/usr/bin/env bash

set -Eeuo pipefail

script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [[ -n "${1-""}" ]]; then
    profile_dir="${1-"${script_path}/configs/xfce"}"
    shift 1
fi
work_dir="$script_path/work"
cache_dir="$work_dir/alteriso_cache"

mkdir -p "$work_dir/archiso"
mkdir -p "$cache_dir"

# Generate archiso profile
"$script_path/gen.sh" -o "$work_dir/profile" "$profile_dir"

sudo ALTERISO_PACMAN_CACHE="$cache_dir" \
    ../archiso/mkarchiso -v \
    -w "$work_dir/archiso" \
    -o "$script_path/out" \
    "$work_dir/profile"

# sudo ../archiso/mkarchiso \
#     -v \
#     -w "$work_dir/archiso" \
#     -o "$script_path/out" \
#     "$work_dir/profile"
