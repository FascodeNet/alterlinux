#!/usr/bin/env bash

set -Eeuo pipefail
script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
rm -rf "$script_path/out"
profile_dir="${1-""${script_path}/configs/xfce""}"
"$script_path/gen.sh" "$profile_dir"
sudo ../archiso/mkarchiso -v -w "$script_path/work" -o "$script_path/out" "$script_path/out/$(basename "$profile_dir")"
