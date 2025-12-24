#!/usr/bin/env bash

set -Eeuo pipefail

# Determine script path
script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
profile_dir="${1-"${script_path}/configs/xfce"}"
if [[ -n "${1-""}" ]]; then
    shift 1
fi
work_dir="$script_path/work"

# Build the Go binary
binfile="$(mktemp -u)"
go build -o "$binfile" "$script_path/src"

# Set mkarchiso path
PATH="$(realpath "$script_path/../archiso/"):$PATH"
export PATH

# Execute the build command
"$binfile" profile \
    --bootloaders "$script_path/bootloaders/" \
    --modules "$script_path/modules/" \
    build \
    --workdir "$work_dir" \
    --outdir "$script_path/out" \
    "$profile_dir" "$@"

# Clean up
"$binfile" clean --workdir "$work_dir"
rm "$binfile"
